//
//  LLMInferenceService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation
import MediaPipeTasksGenAI

/// Service responsible for LLM inference using MediaPipe
final class MediaPipeInferenceEngine: LLMInferenceEngine {
    private var llmInference: LlmInference?
    private var isInitialized = false
    private var currentModelPath: String?
    private var appliesGemmaPromptTemplate = true

    private(set) var modelName: String?
    private(set) var backendPreference: LLMBackendPreference?
    private(set) var modelLoadTimeMs: Int64?

    let engineKind: LLMEngineKind = .mediaPipe

    /// Initialize the LLM with the model file
    /// - Parameters:
    ///   - model: The selected model metadata.
    ///   - modelPath: Absolute path to the .bin model file.
    /// - Throws: Error if initialization fails
    func initialize(model: LLMModel, modelPath: String) async throws {
        // If already initialized with the same path, return early
        if isInitialized && currentModelPath == modelPath { return }

        modelName = model.name
        backendPreference = model.backendPreference
        appliesGemmaPromptTemplate = model.requiresPromptTemplateFormatting

        let loadStartTime = Date()
        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 1024

        llmInference = try LlmInference(options: options)
        modelLoadTimeMs = Int64(Date().timeIntervalSince(loadStartTime) * 1000)
        isInitialized = true
        currentModelPath = modelPath
    }

    /// Generate a response for the given prompt
    /// - Parameter prompt: The input text prompt
    /// - Returns: The generated response text
    /// - Throws: Error if inference fails or model not initialized
    func generateResponse(prompt: LLMUserPrompt) async throws -> String {
        print("🤖 LLM Service: Generating response...")
        guard let llmInference = llmInference, isInitialized else {
            print("🤖 LLM Service: Model not initialized")
            throw LLMError.modelNotInitialized
        }

        let formattedPrompt = formatPromptIfNeeded(prompt)

        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    print("🤖 LLM Service: Calling internal generateResponse")
                    let result = try llmInference.generateResponse(inputText: formattedPrompt)
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
    func generateResponseStream(
        prompt: LLMUserPrompt,
        onPartialResponse: @escaping @MainActor (String) -> Void
    ) async throws {
        guard let llmInference = llmInference, isInitialized else {
            throw LLMError.modelNotInitialized
        }

        let formattedPrompt = formatPromptIfNeeded(prompt)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try llmInference.generateResponseAsync(
                    inputText: formattedPrompt,
                    progress: { partialResponse, error in
                        if let error = error {
                            print("🤖 LLM Service: Streaming Error \(error)")
                            return
                        }
                        
                        if let partialResponse = partialResponse {
                            Task { @MainActor in
                                onPartialResponse(partialResponse)
                            }
                        }
                    },
                    completion: {
                        continuation.resume()
                    }
                )
            } catch {
                print("🤖 LLM Service: Error \(error)")
                continuation.resume(throwing: error)
            }
        }
    }

    func reset() async {
        llmInference = nil
        isInitialized = false
        currentModelPath = nil
        modelName = nil
        backendPreference = nil
        modelLoadTimeMs = nil
    }

    private func formatPromptIfNeeded(_ prompt: LLMUserPrompt) -> String {
        guard appliesGemmaPromptTemplate else { return prompt.text }

        return """
        <start_of_turn>user
        \(prompt.text)<end_of_turn>
        <start_of_turn>model
        """
    }
}

typealias LLMInferenceService = MediaPipeInferenceEngine
