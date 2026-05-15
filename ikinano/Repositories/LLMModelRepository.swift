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

        if !existingModels.contains(where: { $0.localFilename == "gemma-2b-it-gpu-int4.bin" }) {
            let mediaPipeModel = LLMModel(
                name: "Gemma 2B (int4)",
                urlString: "https://huggingface.co/devpicon/gemma-2b-ios/resolve/main/gemma-2b-it-gpu-int4.bin",
                localFilename: "gemma-2b-it-gpu-int4.bin",
                isCustom: false,
                engineKind: .mediaPipe,
                backendPreference: .automatic,
                modelFormat: .bin,
                supportsStreaming: true,
                supportsSpeculativeDecoding: false,
                requiresPromptTemplateFormatting: true
            )
            modelContext.insert(mediaPipeModel)
        }

        if !existingModels.contains(where: { $0.localFilename == "gemma-4-E2B-it.litertlm" }) {
            let liteRTModel = LLMModel(
                name: "Gemma 4 E2B (LiteRT-LM CPU)",
                urlString: "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm",
                localFilename: "gemma-4-E2B-it.litertlm",
                isCustom: false,
                engineKind: .liteRTLM,
                backendPreference: .cpu,
                modelFormat: .litertlm,
                supportsStreaming: true,
                supportsSpeculativeDecoding: true,
                expectedSizeBytes: 2_588_147_712,
                sha256: "181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c",
                defaultContextLength: 4096,
                requiresPromptTemplateFormatting: false
            )
            modelContext.insert(liteRTModel)
        }

        try modelContext.save()
    }
    
    func fetchAllModels() throws -> [LLMModel] {
        var descriptor = FetchDescriptor<LLMModel>()
        descriptor.sortBy = [SortDescriptor(\.name)]
        return try modelContext.fetch(descriptor)
    }
    
    func addModel(name: String, urlString: String, localFilename: String) throws {
        let modelFormat: LLMModelFormat = localFilename.hasSuffix(".litertlm") ? .litertlm : .bin
        let newModel = LLMModel(
            name: name,
            urlString: urlString,
            localFilename: localFilename,
            isCustom: true,
            engineKind: modelFormat == .litertlm ? .liteRTLM : .mediaPipe,
            backendPreference: modelFormat == .litertlm ? .cpu : .automatic,
            modelFormat: modelFormat,
            requiresPromptTemplateFormatting: modelFormat == .bin
        )
        modelContext.insert(newModel)
        try modelContext.save()
    }
    
    func removeModel(_ model: LLMModel) throws {
        modelContext.delete(model)
        try modelContext.save()
    }

    func deleteAllModels() throws {
        let descriptor = FetchDescriptor<LLMModel>()
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
}
