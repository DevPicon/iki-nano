import Foundation

struct LLMUserPrompt: Sendable {
    let text: String

    static func user(_ text: String) -> LLMUserPrompt {
        LLMUserPrompt(text: text)
    }
}
