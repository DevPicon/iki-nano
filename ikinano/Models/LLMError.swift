import Foundation

enum LLMError: LocalizedError {
    case modelNotFound(String)
    case initializationFailed(String)
    case inferenceFailed(String)
    case streamingFailed(String)
    case engineNotInitialized
    case modelNotInitialized
    case invalidInput(String)
    case lowMemory(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Model not found at path: \(path)"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .inferenceFailed(let message):
            return "Inference failed: \(message)"
        case .streamingFailed(let message):
            return "Streaming failed: \(message)"
        case .engineNotInitialized:
            return "Engine not initialized. Please call initialize() first."
        case .modelNotInitialized:
            return "Model not initialized. Please call initializeModel() first."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .lowMemory(let message):
            return "Memory pressure too high: \(message)"
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
