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

    /// Initialize the LLM with the model file
    /// - Parameter modelPath: Absolute path to the .bin model file
    /// - Throws: Error if initialization fails
    func initialize(modelPath: String) async throws {
        // If already initialized with the same path, return early
        if isInitialized && currentModelPath == modelPath { return }

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 512

        llmInference = try LlmInference(options: options)
        isInitialized = true
        currentModelPath = modelPath
    }

    /// Generate a response for the given prompt
    /// - Parameter prompt: The input text prompt
    /// - Returns: The generated response text
    /// - Throws: Error if inference fails or model not initialized
    func generateResponse(prompt: String) async throws -> String {
        print("🤖 LLM Service: Generating response...")
        guard let llmInference = llmInference, isInitialized else {
            print("🤖 LLM Service: Model not initialized")
            throw LLMError.modelNotInitialized
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    print("🤖 LLM Service: Calling internal generateResponse")
                    let result = try llmInference.generateResponse(inputText: prompt)
                    print("🤖 LLM Service: Generated \(result.count) characters")
                    continuation.resume(returning: result)
                } catch {
                    print("🤖 LLM Service: Error \(error)")
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
        guard let llmInference = llmInference, isInitialized else {
            throw LLMError.modelNotInitialized
        }

        // For now, use non-streaming and return full response
        // MediaPipe GenAI API may not support streaming in this version
        let result = try await generateResponse(prompt: prompt)
        await MainActor.run {
            onPartialResponse(result)
        }
    }

    /// Generate a response with comprehensive metrics collection
    /// - Parameters:
    ///   - capability: The inference capability being used
    ///   - inputText: The raw input text
    ///   - prompt: The formatted prompt with instructions
    /// - Returns: InferenceMetrics containing output and performance data
    /// - Throws: Error if inference fails or model not initialized
    func generateResponseWithMetrics(
        capability: InferenceCapability,
        inputText: String,
        prompt: String
    ) async throws -> InferenceMetrics {
        guard llmInference != nil, isInitialized else {
            throw LLMError.modelNotInitialized
        }

        let totalStartTime = Date()
        let startMemory = MemoryTracker.getCurrentMemoryUsageMB()

        let inputTokenCount = TokenCounter.estimateTokens(text: inputText)
        let inputCharCount = inputText.count

        let outputText = try await generateResponse(prompt: prompt)

        let totalEndTime = Date()
        let endMemory = MemoryTracker.getCurrentMemoryUsageMB()
        let peakMemory = MemoryTracker.getPeakMemoryMB()

        let outputTokenCount = TokenCounter.estimateTokens(text: outputText)
        let outputCharCount = outputText.count

        let totalTimeMs = Int64(totalEndTime.timeIntervalSince(totalStartTime) * 1000)

        return InferenceMetrics(
            capability: capability,
            inputText: inputText,
            inputTokenCount: inputTokenCount,
            inputCharCount: inputCharCount,
            outputText: outputText,
            outputTokenCount: outputTokenCount,
            outputCharCount: outputCharCount,
            modelLoadTimeMs: nil,
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
