//
//  MainViewModel.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation
import Observation

/// Main ViewModel that manages the application state and coordinates services
@Observable
final class MainViewModel {
    // MARK: - Properties
    let modelFileService = ModelFileService()
    let llmInferenceService = LLMInferenceService()
    var selectedCapability: InferenceCapability?

    var state: AppState = .idle
    
    // The currently selected model for inference
    var activeModel: LLMModel?

    // MARK: - Initialization
    init() {
        checkModelAvailability()
    }

    // MARK: - Model Management
    /// Check if model is already downloaded
    private func checkModelAvailability() {
        state = .idle
    }
    
    /// Initialize the model (called when user taps Continue)
    @MainActor
    func continueToInference() async {
        state = .initializing
        await initializeModel()
    }

    /// Initialize the LLM model
    private func initializeModel() async {
        guard let activeModel = activeModel else {
            await MainActor.run {
                state = .error("No active model selected")
            }
            return
        }
        
        let modelPath = modelFileService.modelFilePath(for: activeModel).path

        do {
            try await llmInferenceService.initialize(modelPath: modelPath)
            await MainActor.run {
                state = .ready
            }
        } catch {
            await MainActor.run {
                state = .error("Model initialization failed: \(error.localizedDescription)")
            }
        }
    }

    /// Delete the downloaded model
    @MainActor
    func deleteModel() {
        guard let activeModel = activeModel else { return }
        
        state = .deleting
        
        Task {
            // Add delay for better UX
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let result = modelFileService.deleteModel(activeModel)

            switch result {
            case .success:
                state = .idle
            case .failure(let error):
                state = .error("Failed to delete model: \(error.localizedDescription)")
            }
        }
    }
}
