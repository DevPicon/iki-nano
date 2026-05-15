import Foundation

enum LLMInferenceEngineFactory {
    static func makeEngine(for model: LLMModel) -> LLMInferenceEngine {
        switch model.engineKind {
        case .mediaPipe:
            return MediaPipeInferenceEngine()
        case .liteRTLM:
            return LiteRTLMInferenceEngine()
        }
    }
}
