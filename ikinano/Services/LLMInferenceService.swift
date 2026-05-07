//
//  LLMInferenceService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation
import MediaPipeTasksGenAI

private final class StreamAggregationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var finalOutputText = ""
    private var ttft: Int64?

    func append(_ partial: String, startedAt: Date) -> String {
        lock.lock()
        defer { lock.unlock() }

        if ttft == nil {
            ttft = Int64(Date().timeIntervalSince(startedAt) * 1000)
        }

        finalOutputText += partial
        return finalOutputText
    }

    func snapshot() -> (outputText: String, ttft: Int64?) {
        lock.lock()
        defer { lock.unlock() }
        return (finalOutputText, ttft)
    }
}

actor MediaPipeLLMEngine: LLMEngine {
    private var llmInference: LlmInference?
    private var currentModelPath: String?
    private var currentSession: LlmInference.Session?

    func initialize(modelPath: String) async throws {
        if llmInference != nil, currentModelPath == modelPath {
            return
        }

        await releaseResources()

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 1024

        llmInference = try LlmInference(options: options)
        currentModelPath = modelPath
    }

    func generateResponse(prompt: String) async throws -> String {
        print("🤖 LLM Engine: Generating response...")
        let session = try makeSession()

        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    try session.addQueryChunk(inputText: prompt)
                    let result = try session.generateResponse()
                    Task { await self.clearSessionIfMatching(session) }
                    continuation.resume(returning: result)
                } catch {
                    Task { await self.clearSessionIfMatching(session) }
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func generateResponseStream(
        prompt: String,
        onPartialResponse: @escaping @Sendable (String) -> Void
    ) async throws {
        let session = try makeSession()
        try session.addQueryChunk(inputText: prompt)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let lock = NSLock()
            var hasResumed = false

            func resumeOnce(with result: Result<Void, Error>) {
                lock.lock()
                defer { lock.unlock() }

                guard !hasResumed else { return }
                hasResumed = true

                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            do {
                try session.generateResponseAsync(
                    progress: { partialResponse, error in
                        if let error {
                            print("🤖 LLM Engine: Streaming Error \(error)")
                            Task { self.clearSessionIfMatching(session) }
                            resumeOnce(with: .failure(error))
                            return
                        }

                        if let partialResponse {
                            onPartialResponse(partialResponse)
                        }
                    },
                    completion: {
                        Task { self.clearSessionIfMatching(session) }
                        resumeOnce(with: .success(()))
                    }
                )
            } catch {
                Task { self.clearSessionIfMatching(session) }
                resumeOnce(with: .failure(error))
            }
        }
    }

    func cancelActiveGeneration() async {
        guard let currentSession else { return }

        do {
            try currentSession.cancelGenerateResponseAsync()
        } catch {
            print("🤖 LLM Engine: Failed to cancel session \(error)")
        }

        self.currentSession = nil
    }

    func releaseResources() async {
        await cancelActiveGeneration()
        currentSession = nil
        llmInference = nil
        currentModelPath = nil
    }

    private func makeSession() throws -> LlmInference.Session {
        guard let llmInference else {
            throw LLMError.modelNotInitialized
        }

        let session = try LlmInference.Session(llmInference: llmInference)
        currentSession = session
        return session
    }

    private func clearSessionIfMatching(_ session: LlmInference.Session) {
        guard currentSession === session else { return }
        currentSession = nil
    }
}

/// Service responsible for metrics and higher-level inference orchestration.
final class LLMInferenceService {
    private let engine: LLMEngine

    init(engine: LLMEngine = MediaPipeLLMEngine()) {
        self.engine = engine
    }

    func initialize(modelPath: String) async throws {
        try await engine.initialize(modelPath: modelPath)
    }

    func cancelActiveGeneration() {
        Task {
            await engine.cancelActiveGeneration()
        }
    }

    func releaseResources() {
        Task {
            await engine.releaseResources()
        }
    }

    func generateResponse(prompt: String) async throws -> String {
        try await engine.generateResponse(prompt: prompt)
    }

    func generateResponseStream(
        prompt: String,
        onPartialResponse: @escaping @Sendable (String) -> Void
    ) async throws {
        try await engine.generateResponseStream(
            prompt: prompt,
            onPartialResponse: onPartialResponse
        )
    }

    /// Generate a response with comprehensive metrics collection
    /// - Parameters:
    ///   - capability: The inference capability being used
    ///   - inputText: The raw input text
    ///   - prompt: The formatted prompt with instructions
    ///   - onPartialResponse: Optional callback for streaming
    /// - Returns: InferenceMetrics containing output and performance data
    /// - Throws: Error if inference fails or model not initialized
    func generateResponseWithMetrics(
        capability: InferenceCapability,
        inputText: String,
        prompt: String,
        onPartialResponse: ((String) -> Void)? = nil
    ) async throws -> InferenceMetrics {
        let totalStartTime = Date()
        let startMemory = MemoryTracker.getCurrentMemoryUsageMB()

        let inputTokenCount = TokenCounter.estimateTokens(text: inputText)
        let inputCharCount = inputText.count

        let aggregationBox = StreamAggregationBox()
        var finalOutputText = ""
        var ttft: Int64? = nil

        if let onPartialResponse {
            try await generateResponseStream(prompt: prompt) { partial in
                let cumulativeText = aggregationBox.append(partial, startedAt: totalStartTime)
                onPartialResponse(cumulativeText)
            }
            let snapshot = aggregationBox.snapshot()
            finalOutputText = snapshot.outputText
            ttft = snapshot.ttft
        } else {
            finalOutputText = try await generateResponse(prompt: prompt)
        }

        let totalEndTime = Date()
        let endMemory = MemoryTracker.getCurrentMemoryUsageMB()
        let peakMemory = MemoryTracker.getPeakMemoryMB()

        let outputTokenCount = TokenCounter.estimateTokens(text: finalOutputText)
        let outputCharCount = finalOutputText.count

        let totalTimeMs = Int64(totalEndTime.timeIntervalSince(totalStartTime) * 1000)

        return InferenceMetrics(
            capability: capability,
            inputText: inputText,
            inputTokenCount: inputTokenCount,
            inputCharCount: inputCharCount,
            outputText: finalOutputText,
            outputTokenCount: outputTokenCount,
            outputCharCount: outputCharCount,
            modelLoadTimeMs: nil,
            ttftMs: ttft,
            inferenceTimeMs: totalTimeMs,
            totalTimeMs: totalTimeMs,
            memoryUsedMB: endMemory - startMemory,
            peakMemoryMB: peakMemory
        )
    }
}

// MARK: - LLM Errors
enum LLMError: LocalizedError {
    case modelNotInitialized

    var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "Model has not been initialized. Please download and initialize the model first."
        }
    }
}
