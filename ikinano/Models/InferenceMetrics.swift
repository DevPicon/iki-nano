//
//  InferenceMetrics.swift
//  ikinano
//

import Foundation

struct InferenceMetrics: Identifiable {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    let capability: InferenceCapability
    var platform: String = "iOS/Gemma 2B"

    let inputText: String
    let inputTokenCount: Int
    let inputCharCount: Int

    let outputText: String
    let outputTokenCount: Int
    let outputCharCount: Int

    let modelLoadTimeMs: Int64?
    let ttftMs: Int64?
    let inferenceTimeMs: Int64
    let totalTimeMs: Int64

    let memoryUsedMB: Int64
    let peakMemoryMB: Int64
}

enum InferenceCapability: String, Codable {
    case summarization
    case proofreading
    case rewriteFormal
    case rewriteCasual
    case rewriteConcise

    var displayName: String {
        switch self {
        case .summarization: return "Summarization"
        case .proofreading: return "Proofreading"
        case .rewriteFormal: return "Rewrite (Formal)"
        case .rewriteCasual: return "Rewrite (Casual)"
        case .rewriteConcise: return "Rewrite (Concise)"
        }
    }

    var description: String {
        switch self {
        case .summarization: return "Summarize long texts into concise key points"
        case .proofreading: return "Fix grammar, spelling, and punctuation errors"
        case .rewriteFormal: return "Rewrite text in a professional, formal tone"
        case .rewriteCasual: return "Rewrite text in a friendly, conversational tone"
        case .rewriteConcise: return "Rewrite text to be more direct and concise"
        }
    }

    func buildPrompt(with text: String) -> String {
        let rawPrompt: String

        switch self {
        case .summarization:
            rawPrompt = """
            Summarize the following text in a concise and clear way.
            Keep the key ideas, remove redundancies, and avoid adding new information.
            Return the summary in one short paragraph.
            Do not include any introductory phrases. Return ONLY the summary text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .proofreading:
            rawPrompt = """
            Proofread the following text. Fix grammar, spelling, punctuation, and syntax errors.
            Preserve the original meaning and style.
            Return ONLY the corrected text without explanations.

            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteFormal:
            rawPrompt = """
            Rewrite the following text in a formal, professional tone.
            Preserve the original meaning, improve clarity and grammar,
            and remove casual expressions or slang.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteCasual:
            rawPrompt = """
            Rewrite the following text in a casual, friendly tone.
            Preserve the original meaning, use conversational language,
            and make it more approachable.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteConcise:
            rawPrompt = """
            Rewrite the following text to be more concise and direct.
            Remove unnecessary words while preserving all key information.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        }

        return """
        <start_of_turn>user
        \(rawPrompt)<end_of_turn>
        <start_of_turn>model
        """
    }
}
