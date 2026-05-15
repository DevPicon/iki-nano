import Foundation

@MainActor
protocol LLMInferenceEngine: AnyObject {
    var engineKind: LLMEngineKind { get }
    var modelName: String? { get }
    var backendPreference: LLMBackendPreference? { get }
    var modelLoadTimeMs: Int64? { get }

    func initialize(model: LLMModel, modelPath: String) async throws
    func generateResponse(prompt: LLMUserPrompt) async throws -> String
    func generateResponseStream(
        prompt: LLMUserPrompt,
        onPartialResponse: @escaping @MainActor (String) -> Void
    ) async throws
    func reset() async
}

extension LLMInferenceEngine {
    func generateResponseWithMetrics(
        capability: InferenceCapability,
        inputText: String,
        prompt: LLMUserPrompt,
        onPartialResponse: (@MainActor (String) -> Void)? = nil
    ) async throws -> InferenceMetrics {
        let totalStartTime = Date()
        let startMemory = MemoryTracker.getCurrentMemoryUsageMB()

        let inputTokenCount = TokenCounter.estimateTokens(text: inputText)
        let inputCharCount = inputText.count

        let streamAccumulator = InferenceStreamAccumulator(totalStartTime: totalStartTime)
        var finalOutputText = ""

        if let onPartialResponse {
            try await generateResponseStream(prompt: prompt) { partial in
                let cumulativeText = streamAccumulator.append(partial)
                onPartialResponse(cumulativeText)
            }
            finalOutputText = streamAccumulator.outputText
        } else {
            finalOutputText = try await generateResponse(prompt: prompt)
        }

        let totalEndTime = Date()
        let endMemory = MemoryTracker.getCurrentMemoryUsageMB()
        let peakMemory = MemoryTracker.getPeakMemoryMB()

        let outputTokenCount = TokenCounter.estimateTokens(text: finalOutputText)
        let outputCharCount = finalOutputText.count

        let totalTimeMs = Int64(totalEndTime.timeIntervalSince(totalStartTime) * 1000)

        return InferenceMetrics(
            capability: capability,
            platform: "iOS/\(engineKind.displayName)",
            modelName: modelName,
            engineKind: engineKind.rawValue,
            backend: backendPreference?.rawValue,
            inputText: inputText,
            inputTokenCount: inputTokenCount,
            inputCharCount: inputCharCount,
            outputText: finalOutputText,
            outputTokenCount: outputTokenCount,
            outputCharCount: outputCharCount,
            modelLoadTimeMs: modelLoadTimeMs,
            ttftMs: streamAccumulator.ttftMs,
            inferenceTimeMs: totalTimeMs,
            totalTimeMs: totalTimeMs,
            memoryUsedMB: endMemory - startMemory,
            peakMemoryMB: peakMemory
        )
    }
}

@MainActor
private final class InferenceStreamAccumulator {
    private let totalStartTime: Date

    private(set) var outputText = ""
    private(set) var ttftMs: Int64?

    init(totalStartTime: Date) {
        self.totalStartTime = totalStartTime
    }

    func append(_ partial: String) -> String {
        if ttftMs == nil {
            ttftMs = Int64(Date().timeIntervalSince(totalStartTime) * 1000)
        }
        outputText += partial
        return outputText
    }
}
