import Foundation

enum LLMEngineKind: String, Codable, CaseIterable {
    case mediaPipe
    case liteRTLM

    var displayName: String {
        switch self {
        case .mediaPipe:
            return "MediaPipe"
        case .liteRTLM:
            return "LiteRT-LM"
        }
    }
}

enum LLMBackendPreference: String, Codable, CaseIterable {
    case cpu
    case gpu
    case automatic

    var displayName: String {
        switch self {
        case .cpu:
            return "CPU"
        case .gpu:
            return "GPU"
        case .automatic:
            return "Auto"
        }
    }
}

enum LLMModelFormat: String, Codable, CaseIterable {
    case bin
    case litertlm

    var displayName: String {
        switch self {
        case .bin:
            return ".bin"
        case .litertlm:
            return ".litertlm"
        }
    }
}
