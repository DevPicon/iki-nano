import Foundation

@MainActor
class LiteRTLMInferenceEngine: LLMInferenceEngine {
    let engineKind: LLMEngineKind = .liteRTLM
    private(set) var modelName: String?
    private(set) var backendPreference: LLMBackendPreference?
    private(set) var modelLoadTimeMs: Int64?
    
    private let bridge = LiteRTLMBridge()
    private var isInitialized = false
    
    func initialize(model: LLMModel, modelPath: String) async throws {
        let startTime = Date()
        
        self.modelName = model.name
        self.backendPreference = model.backendPreference
        
        let bridgeBackend: LiteRTLMBackend
        switch model.backendPreference {
        case .cpu: bridgeBackend = .CPU
        case .gpu: bridgeBackend = .GPU
        case .automatic: bridgeBackend = .automatic
        }
        
        do {
            try bridge.initialize(
                withModelPath: modelPath,
                backend: bridgeBackend,
                enableSpeculativeDecoding: model.supportsSpeculativeDecoding,
                maxTokens: model.defaultContextLength ?? 4096
            )
            self.modelLoadTimeMs = Int64(Date().timeIntervalSince(startTime) * 1000)
            self.isInitialized = true
        } catch {
            let nsError = error as NSError
            let errorCode = LiteRTLMErrorCode(rawValue: nsError.code) ?? .initializationFailed
            
            switch errorCode {
            case .modelNotFound:
                throw LLMError.modelNotFound(modelPath)
            case .outOfMemory:
                throw LLMError.lowMemory(nsError.localizedDescription)
            case .invalidInput:
                throw LLMError.invalidInput(nsError.localizedDescription)
            case .initializationFailed:
                throw LLMError.initializationFailed(nsError.localizedDescription)
            case .inferenceFailed, .streamingFailed, .unsupportedBackend, .none:
                throw LLMError.initializationFailed(nsError.localizedDescription)
            @unknown default:
                throw LLMError.initializationFailed(nsError.localizedDescription)
            }
        }
    }
    
    func generateResponse(prompt: LLMUserPrompt) async throws -> String {
        guard isInitialized else {
            throw LLMError.engineNotInitialized
        }

        let jsonPrompt = try wrapPromptInJson(prompt)
        let rawResponse = bridge.sendMessage(jsonPrompt)
        return try parseJsonResponse(rawResponse)
    }

    func generateResponseStream(
        prompt: LLMUserPrompt,
        onPartialResponse: @escaping @MainActor (String) -> Void
    ) async throws {
        guard isInitialized else {
            throw LLMError.engineNotInitialized
        }

        let jsonPrompt = try wrapPromptInJson(prompt)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasResumed = false

            bridge.sendMessageAsync(jsonPrompt) { chunk in
                let cleanText = self.extractTextFromChunk(chunk)
                Task { @MainActor in
                    onPartialResponse(cleanText)
                }
            } onCompletion: { success, errorMessage in
                if !hasResumed {
                    hasResumed = true
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: LLMError.streamingFailed(errorMessage ?? "Unknown streaming error"))
                    }
                }
            }
        }
    }

    func reset() async {
        bridge.resetConversation()
    }

    private func wrapPromptInJson(_ prompt: LLMUserPrompt) throws -> String {
        let message: [String: String] = [
            "role": "user",
            "content": prompt.text
        ]

        let data = try JSONSerialization.data(withJSONObject: [message], options: [])
        return String(data: data, encoding: .utf8) ?? prompt.text
    }

    /// Extracts plain text from the LiteRT-LM structured JSON response format.
    /// Format: {"role":"assistant","content":[{"type":"text","text":"..."}]}
    private func parseJsonResponse(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else { return jsonString }

        // Sometimes the engine returns multiple JSON objects concatenated
        // We'll try to parse it as a single object first
        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(LiteRTLMMessage.self, from: data)
            return message.content.compactMap { $0.text }.joined()
        } catch {
            // Fallback for concatenated JSONs or raw text
            return jsonString
        }
    }

    private func extractTextFromChunk(_ chunk: String) -> String {
        guard let data = chunk.data(using: .utf8) else { return chunk }

        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(LiteRTLMMessage.self, from: data)
            return message.content.compactMap { $0.text }.joined()
        } catch {
            // If it's not a valid JSON chunk, it might be raw text or partial JSON
            return chunk
        }
    }
    }

    // MARK: - LiteRT-LM Response Models
    struct LiteRTLMMessage: Codable {
    let role: String?
    let content: [LiteRTLMContent]
    }

    struct LiteRTLMContent: Codable {
    let type: String
    let text: String?
    }

