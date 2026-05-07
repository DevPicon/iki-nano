import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ModelManagementViewModel {
    var showingAddSheet = false
    var newModelName = ""
    var newModelURL = ""
    var newModelFilename = ""

    private var downloadingModelIDs: Set<UUID> = []
    private var downloadProgressByModelID: [UUID: Double] = [:]

    private var modelContext: ModelContext?
    private var appViewModel: MainViewModel?

    func configure(modelContext: ModelContext, appViewModel: MainViewModel) {
        self.modelContext = modelContext
        self.appViewModel = appViewModel
    }

    var canSaveNewModel: Bool {
        !newModelName.isEmpty && !newModelURL.isEmpty && !newModelFilename.isEmpty
    }

    func presentAddSheet() {
        showingAddSheet = true
    }

    func dismissAddSheet() {
        showingAddSheet = false
    }

    func saveNewModel() {
        guard let modelContext else { return }

        let repository = LLMModelRepository(modelContext: modelContext)
        try? repository.addModel(
            name: newModelName,
            urlString: newModelURL,
            localFilename: newModelFilename
        )

        newModelName = ""
        newModelURL = ""
        newModelFilename = ""
        showingAddSheet = false
    }

    func deleteModelRecord(_ model: LLMModel) {
        if model.isDownloaded {
            _ = appViewModel?.modelFileService.deleteModel(model)
        }

        if appViewModel?.activeModel?.id == model.id {
            appViewModel?.activeModel = nil
            appViewModel?.state = .idle
        }

        downloadingModelIDs.remove(model.id)
        downloadProgressByModelID.removeValue(forKey: model.id)

        guard let modelContext else { return }
        let repository = LLMModelRepository(modelContext: modelContext)
        try? repository.removeModel(model)
    }

    func selectModel(_ model: LLMModel) {
        guard let appViewModel else { return }

        appViewModel.activeModel = model
        Task {
            await appViewModel.continueToInference()
        }
    }

    func deleteDownloadedModel(_ model: LLMModel) {
        _ = appViewModel?.modelFileService.deleteModel(model)

        if appViewModel?.activeModel?.id == model.id {
            appViewModel?.activeModel = nil
            appViewModel?.state = .idle
        }

        downloadingModelIDs.remove(model.id)
        downloadProgressByModelID.removeValue(forKey: model.id)
    }

    func startDownload(for model: LLMModel) {
        guard let appViewModel else { return }

        downloadingModelIDs.insert(model.id)
        downloadProgressByModelID[model.id] = 0.0

        appViewModel.modelFileService.downloadModel(
            model,
            onProgress: { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgressByModelID[model.id] = progress
                }
            },
            onCompletion: { [weak self] _ in
                Task { @MainActor in
                    self?.downloadingModelIDs.remove(model.id)
                    self?.downloadProgressByModelID.removeValue(forKey: model.id)
                }
            }
        )
    }

    func cancelDownload(for model: LLMModel) {
        appViewModel?.modelFileService.cancelDownload(for: model)
        downloadingModelIDs.remove(model.id)
        downloadProgressByModelID.removeValue(forKey: model.id)
    }

    func isDownloading(_ model: LLMModel) -> Bool {
        downloadingModelIDs.contains(model.id)
    }

    func downloadProgress(for model: LLMModel) -> Double {
        downloadProgressByModelID[model.id] ?? 0.0
    }
}
