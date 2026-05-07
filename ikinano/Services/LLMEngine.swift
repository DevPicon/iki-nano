import Foundation

protocol LLMEngine: Sendable {
    func initialize(modelPath: String) async throws
    func generateResponse(prompt: String) async throws -> String
    func generateResponseStream(
        prompt: String,
        onPartialResponse: @escaping @Sendable (String) -> Void
    ) async throws
    func cancelActiveGeneration() async
    func releaseResources() async
}
