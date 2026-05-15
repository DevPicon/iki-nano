//
//  MetricsCard.swift
//  ikinano
//

import SwiftUI

struct MetricsCard: View {
    let metrics: InferenceMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.bold)

            if let modelName = metrics.modelName {
                MetricRow(label: "Model", value: modelName)
            }
            if let engineKind = metrics.engineKind {
                MetricRow(label: "Engine", value: metrics.backend.map { "\(engineKind) / \($0)" } ?? engineKind)
            }
            MetricRow(label: "Latency", value: "\(formatNumber(metrics.inferenceTimeMs)) ms")
            if let ttft = metrics.ttftMs {
                MetricRow(label: "TTFT", value: "\(formatNumber(ttft)) ms")
            }
            MetricRow(label: "Tokens", value: "\(formatNumber(metrics.inputTokenCount)) → \(formatNumber(metrics.outputTokenCount))")
            MetricRow(label: "Characters", value: "\(formatNumber(metrics.inputCharCount)) → \(formatNumber(metrics.outputCharCount))")
            MetricRow(label: "Memory", value: "\(formatNumber(metrics.memoryUsedMB)) MB")

            if let loadTime = metrics.modelLoadTimeMs {
                MetricRow(label: "Load Time", value: "\(formatNumber(loadTime)) ms")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatNumber(_ number: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MetricsCard(
        metrics: InferenceMetrics(
            capability: .summarization,
            platform: "iOS/MediaPipe",
            modelName: "Gemma 2B (int4)",
            engineKind: LLMEngineKind.mediaPipe.rawValue,
            backend: LLMBackendPreference.automatic.rawValue,
            inputText: "Sample input",
            inputTokenCount: 100,
            inputCharCount: 500,
            outputText: "Sample output",
            outputTokenCount: 50,
            outputCharCount: 250,
            modelLoadTimeMs: nil,
            ttftMs: 450,
            inferenceTimeMs: 1234,
            totalTimeMs: 1234,
            memoryUsedMB: 245,
            peakMemoryMB: 512
        )
    )
    .padding()
}
