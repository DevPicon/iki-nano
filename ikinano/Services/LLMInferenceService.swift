//
//  LLMInferenceService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation
import MediaPipeTasksGenAI

/// Service responsible for LLM inference using MediaPipe
final class LLMInferenceService {
    private var llmInference: LlmInference?
    private var isInitialized = false
    private var currentModelPath: String?
    private var currentSession: LlmInference.Session?

    /// Initialize the LLM with the model file
    /// - Parameter modelPath: Absolute path to the .bin model file
    /// - Throws: Error if initialization fails
    func initialize(modelPath: String) async throws {
        // If already initialized with the same path, return early
        if isInitialized && currentModelPath == modelPath { return }

        releaseResources()

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 1024

        llmInference = try LlmInference(options: options)
        isInitialized = true
        currentModelPath = modelPath
    }

    func cancelActiveGeneration() {
        guard let currentSession else { return }

        do {
            try currentSession.cancelGenerateResponseAsync()
        } catch {
            print("🤖 LLM Service: Failed to cancel session \(error)")
        }

        self.currentSession = nil
    }

    func releaseResources() {
        cancelActiveGeneration()
        currentSession = nil
        llmInference = nil
        isInitialized = false
        currentModelPath = nil
    }

    private func makeSession() throws -> LlmInference.Session {
        guard let llmInference = llmInference, isInitialized else {
            throw LLMError.modelNotInitialized
        }

        let session = try LlmInference.Session(llmInference: llmInference)
        currentSession = session
        return session
    }

    /// Generate a response for the given prompt
    /// - Parameter prompt: The input text prompt
    /// - Returns: The generated response text
    /// - Throws: Error if inference fails or model not initialized
    func generateResponse(prompt: String) async throws -> String {
        print("🤖 LLM Service: Generating response...")
        let session = try makeSession()

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            Task.detached {
                do {
                    print("🤖 LLM Service: Calling internal generateResponse")
                    try session.addQueryChunk(inputText: prompt)
                    let result = try session.generateResponse()
                    print("🤖 LLM Service: Generated \(result.count) characters")
                    self?.currentSession = nil
                    continuation.resume(returning: result)
                } catch {
                    print("🤖 LLM Service: Error \(error)")
                    self?.currentSession = nil
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Generate a response with streaming updates
    /// - Parameters:
    ///   - prompt: The input text prompt
    ///   - onPartialResponse: Callback for each partial response chunk
    /// - Throws: Error if inference fails or model not initialized
    func generateResponseStream(prompt: String, onPartialResponse: @escaping (String) -> Void) async throws {
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
                        if let error = error {
                            print("🤖 LLM Service: Streaming Error \(error)")
                            self.currentSession = nil
                            resumeOnce(with: .failure(error))
                            return
                        }

                        if let partialResponse = partialResponse {
                            onPartialResponse(partialResponse)
                        }
                    },
                    completion: {
                        self.currentSession = nil
                        resumeOnce(with: .success(()))
                    }
                )
            } catch {
                print("🤖 LLM Service: Error \(error)")
                self.currentSession = nil
                resumeOnce(with: .failure(error))
            }
        }
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
        guard llmInference != nil, isInitialized else {
            throw LLMError.modelNotInitialized
        }

        let totalStartTime = Date()
        let startMemory = MemoryTracker.getCurrentMemoryUsageMB()

        let inputTokenCount = TokenCounter.estimateTokens(text: inputText)
        let inputCharCount = inputText.count

        var finalOutputText = ""
        var ttft: Int64? = nil

        if let onPartialResponse = onPartialResponse {
            try await generateResponseStream(prompt: prompt) { partial in
                if ttft == nil {
                    ttft = Int64(Date().timeIntervalSince(totalStartTime) * 1000)
                }
                finalOutputText += partial
                onPartialResponse(finalOutputText)
            }
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
