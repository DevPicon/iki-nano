//
//  MetricsRepository.swift
//  ikinano
//

import Foundation
import SwiftData

@MainActor
final class MetricsRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveMetrics(_ metrics: InferenceMetrics) throws {
        let entity = metrics.toEntity()
        modelContext.insert(entity)
        try modelContext.save()
    }

    func getAllMetrics() throws -> [InferenceMetrics] {
        let descriptor = FetchDescriptor<MetricsEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    func getMetricsByCapability(_ capability: InferenceCapability) throws -> [InferenceMetrics] {
        let predicate = #Predicate<MetricsEntity> { entity in
            entity.capability == capability.rawValue
        }
        let descriptor = FetchDescriptor<MetricsEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    func getMetricsById(_ id: String) throws -> InferenceMetrics? {
        let predicate = #Predicate<MetricsEntity> { entity in
            entity.id == id
        }
        let descriptor = FetchDescriptor<MetricsEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomain()
    }

    func deleteMetricsById(_ id: String) throws {
        let predicate = #Predicate<MetricsEntity> { entity in
            entity.id == id
        }
        let descriptor = FetchDescriptor<MetricsEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    func deleteAllMetrics() throws {
        try modelContext.delete(model: MetricsEntity.self)
        try modelContext.save()
    }

    func getMetricsCount() throws -> Int {
        let descriptor = FetchDescriptor<MetricsEntity>()
        return try modelContext.fetchCount(descriptor)
    }
}
