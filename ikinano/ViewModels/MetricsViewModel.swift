//
//  MetricsViewModel.swift
//  ikinano
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class MetricsViewModel {
    private let modelContext: ModelContext
    private let repository: MetricsRepository

    var allMetrics: [InferenceMetrics] = []
    var isLoading: Bool = false
    var error: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.repository = MetricsRepository(modelContext: modelContext)
        loadMetrics()
    }

    func loadMetrics() {
        isLoading = true
        error = nil

        do {
            allMetrics = try repository.getAllMetrics()
            isLoading = false
        } catch {
            self.error = "Failed to load metrics: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func getMetrics(for capability: InferenceCapability) -> [InferenceMetrics] {
        do {
            return try repository.getMetricsByCapability(capability)
        } catch {
            self.error = "Failed to load metrics for \(capability.rawValue): \(error.localizedDescription)"
            return []
        }
    }

    func deleteMetrics(_ id: String) {
        do {
            try repository.deleteMetricsById(id)
            loadMetrics()
        } catch {
            self.error = "Failed to delete metrics: \(error.localizedDescription)"
        }
    }

    func deleteAllMetrics() {
        do {
            try repository.deleteAllMetrics()
            loadMetrics()
        } catch {
            self.error = "Failed to delete all metrics: \(error.localizedDescription)"
        }
    }

    func getMetricsCount() -> Int {
        do {
            return try repository.getMetricsCount()
        } catch {
            return 0
        }
    }

    func exportToCSV() -> String {
        var csv = "Timestamp,Platform,Capability,InputTokens,OutputTokens,InferenceTimeMs,MemoryMB\n"

        for metrics in allMetrics {
            let timestamp = ISO8601DateFormatter().string(from: metrics.timestamp)
            csv += "\(timestamp),\(metrics.platform),\(metrics.capability.rawValue),\(metrics.inputTokenCount),\(metrics.outputTokenCount),\(metrics.inferenceTimeMs),\(metrics.memoryUsedMB)\n"
        }

        return csv
    }
}
