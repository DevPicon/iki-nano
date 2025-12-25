//
//  InferenceMetrics.swift
//  ikinano
//

import Foundation

struct InferenceMetrics: Codable, Identifiable {
    let id: String = UUID().uuidString
    let timestamp: Date = Date()
    let capability: InferenceCapability
    let platform: String = "iOS/Gemma 2B"

    let inputText: String
    let inputTokenCount: Int
    let inputCharCount: Int

    let outputText: String
    let outputTokenCount: Int
    let outputCharCount: Int

    let modelLoadTimeMs: Int64?
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
}
