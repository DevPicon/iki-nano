//
//  InferenceMetrics.swift
//  ikinano
//

import Foundation

struct InferenceMetrics: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let capability: InferenceCapability
    let platform: String
    let modelName: String?
    let engineKind: String?
    let backend: String?

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

    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        capability: InferenceCapability,
        platform: String,
        modelName: String?,
        engineKind: String?,
        backend: String?,
        inputText: String,
        inputTokenCount: Int,
        inputCharCount: Int,
        outputText: String,
        outputTokenCount: Int,
        outputCharCount: Int,
        modelLoadTimeMs: Int64?,
        ttftMs: Int64?,
        inferenceTimeMs: Int64,
        totalTimeMs: Int64,
        memoryUsedMB: Int64,
        peakMemoryMB: Int64
    ) {
        self.id = id
        self.timestamp = timestamp
        self.capability = capability
        self.platform = platform
        self.modelName = modelName
        self.engineKind = engineKind
        self.backend = backend
        self.inputText = inputText
        self.inputTokenCount = inputTokenCount
        self.inputCharCount = inputCharCount
        self.outputText = outputText
        self.outputTokenCount = outputTokenCount
        self.outputCharCount = outputCharCount
        self.modelLoadTimeMs = modelLoadTimeMs
        self.ttftMs = ttftMs
        self.inferenceTimeMs = inferenceTimeMs
        self.totalTimeMs = totalTimeMs
        self.memoryUsedMB = memoryUsedMB
        self.peakMemoryMB = peakMemoryMB
    }
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
