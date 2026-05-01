import Foundation
import SwiftData

@MainActor
class LLMModelRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadDefaultModelsIfNeeded() throws {
        let descriptor = FetchDescriptor<LLMModel>()
        let existingModels = try modelContext.fetch(descriptor)
        
        if existingModels.isEmpty {
            let defaultModel = LLMModel(
                name: "Gemma 2B (int4)",
                urlString: "https://huggingface.co/devpicon/gemma-2b-ios/resolve/main/gemma-2b-it-gpu-int4.bin",
                localFilename: "gemma-2b-it-gpu-int4.bin",
                isCustom: false
            )
            modelContext.insert(defaultModel)
            try modelContext.save()
        }
    }
    
    func fetchAllModels() throws -> [LLMModel] {
        var descriptor = FetchDescriptor<LLMModel>()
        descriptor.sortBy = [SortDescriptor(\.name)]
        return try modelContext.fetch(descriptor)
    }
    
    func addModel(name: String, urlString: String, localFilename: String) throws {
        let newModel = LLMModel(
            name: name,
            urlString: urlString,
            localFilename: localFilename,
            isCustom: true
        )
        modelContext.insert(newModel)
        try modelContext.save()
    }
    
    func removeModel(_ model: LLMModel) throws {
        modelContext.delete(model)
        try modelContext.save()
    }
}