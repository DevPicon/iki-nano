//
//  MetricsEntity.swift
//  ikinano
//

import Foundation
import SwiftData

@Model
final class MetricsEntity {
    @Attribute(.unique) var id: String
    var timestamp: Date
    var capability: String
    var platform: String

    var inputText: String
    var inputTokenCount: Int
    var inputCharCount: Int

    var outputText: String
    var outputTokenCount: Int
    var outputCharCount: Int

    var modelLoadTimeMs: Int64?
    var inferenceTimeMs: Int64
    var totalTimeMs: Int64

    var memoryUsedMB: Int64
    var peakMemoryMB: Int64

    init(
        id: String,
        timestamp: Date,
        capability: String,
        platform: String,
        inputText: String,
        inputTokenCount: Int,
        inputCharCount: Int,
        outputText: String,
        outputTokenCount: Int,
        outputCharCount: Int,
        modelLoadTimeMs: Int64?,
        inferenceTimeMs: Int64,
        totalTimeMs: Int64,
        memoryUsedMB: Int64,
        peakMemoryMB: Int64
    ) {
        self.id = id
        self.timestamp = timestamp
        self.capability = capability
        self.platform = platform
        self.inputText = inputText
        self.inputTokenCount = inputTokenCount
        self.inputCharCount = inputCharCount
        self.outputText = outputText
        self.outputTokenCount = outputTokenCount
        self.outputCharCount = outputCharCount
        self.modelLoadTimeMs = modelLoadTimeMs
        self.inferenceTimeMs = inferenceTimeMs
        self.totalTimeMs = totalTimeMs
        self.memoryUsedMB = memoryUsedMB
        self.peakMemoryMB = peakMemoryMB
    }
}

extension InferenceMetrics {
    func toEntity() -> MetricsEntity {
        MetricsEntity(
            id: id,
            timestamp: timestamp,
            capability: capability.rawValue,
            platform: platform,
            inputText: inputText,
            inputTokenCount: inputTokenCount,
            inputCharCount: inputCharCount,
            outputText: outputText,
            outputTokenCount: outputTokenCount,
            outputCharCount: outputCharCount,
            modelLoadTimeMs: modelLoadTimeMs,
            inferenceTimeMs: inferenceTimeMs,
            totalTimeMs: totalTimeMs,
            memoryUsedMB: memoryUsedMB,
            peakMemoryMB: peakMemoryMB
        )
    }
}

extension MetricsEntity {
    func toDomain() -> InferenceMetrics {
        InferenceMetrics(
            capability: InferenceCapability(rawValue: capability) ?? .summarization,
            inputText: inputText,
            inputTokenCount: inputTokenCount,
            inputCharCount: inputCharCount,
            outputText: outputText,
            outputTokenCount: outputTokenCount,
            outputCharCount: outputCharCount,
            modelLoadTimeMs: modelLoadTimeMs,
            inferenceTimeMs: inferenceTimeMs,
            totalTimeMs: totalTimeMs,
            memoryUsedMB: memoryUsedMB,
            peakMemoryMB: peakMemoryMB
        )
    }
}
