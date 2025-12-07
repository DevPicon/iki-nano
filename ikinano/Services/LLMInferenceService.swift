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

    /// Initialize the LLM with the model file
    /// - Parameter modelPath: Absolute path to the .bin model file
    /// - Throws: Error if initialization fails
    func initialize(modelPath: String) async throws {
        guard !isInitialized else { return }

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 512

        llmInference = try LlmInference(options: options)
        isInitialized = true
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
