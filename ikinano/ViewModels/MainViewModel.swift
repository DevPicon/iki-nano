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

    var state: AppState = .idle
    var generatedResponse: String = ""
    
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
    
    /// Check if the active model is downloaded
    func isModelDownloaded() -> Bool {
        guard let activeModel = activeModel else { return false }
        return modelFileService.isModelDownloaded(model: activeModel)
    }

    /// Initialize the model (called when user taps Continue)
    @MainActor
    func continueToInference() async {
        state = .initializing
        await initializeModel()
    }

    /// Download the active model
    @MainActor
    func downloadModel() {
        guard case .idle = state, let activeModel = activeModel else { return }

        state = .downloading(progress: 0.0)

        modelFileService.downloadModel(activeModel, onProgress: { [weak self] progress in
            Task { @MainActor in
                self?.state = .downloading(progress: progress)
            }
        }, onCompletion: { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    await self?.initializeModel()
                case .failure(let error):
                    self?.state = .error("Download failed: \(error.localizedDescription)")
                }
            }
        })
    }

    /// Cancel download for the active model
    @MainActor
    func cancelDownload() {
        guard let activeModel = activeModel else { return }
        modelFileService.cancelDownload(for: activeModel)
        state = .idle
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
                generatedResponse = ""
            case .failure(let error):
                state = .error("Failed to delete model: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Inference
    /// Run inference on the given prompt
    /// - Parameter prompt: User input text
    @MainActor
    func runInference(prompt: String) async {
        print("🚀 Starting inference with prompt: \(prompt.prefix(50))...")
        guard case .ready = state else {
            print("⚠️ State is not ready: \(state)")
            return
        }

        state = .processing
        generatedResponse = ""

        do {
            // Use streaming for better UX
            try await llmInferenceService.generateResponseStream(prompt: prompt) { [weak self] partialResponse in
                guard let self = self else { return }
                print("📦 Received response chunk: \(partialResponse.prefix(50))...")
                self.generatedResponse = partialResponse
            }

            print("✅ Inference completed successfully")
            state = .ready
        } catch {
            print("❌ Inference failed: \(error)")
            state = .error("Inference failed: \(error.localizedDescription)")
        }
    }

    /// Run inference with a task-specific prefix
    /// - Parameters:
    ///   - task: The type of task (summarize, rewrite, etc.)
    ///   - text: The input text
    @MainActor
    func runTaskInference(task: InferenceTask, text: String) async {
        let rawPrompt = task.buildPrompt(with: text)
        
        // Wrap prompt in Gemma instruction format
        let formattedPrompt = """
        <start_of_turn>user
        \(rawPrompt)<end_of_turn>
        <start_of_turn>model
        """
        
        await runInference(prompt: formattedPrompt)
    }
}

// MARK: - Inference Task Types
enum InferenceTask {
    case summarize
    case proofreading
    case rewriteFormal
    case rewriteCasual
    case rewriteConcise

    func buildPrompt(with text: String) -> String {
        switch self {
        case .summarize:
            return """
            Summarize the following text in a concise and clear way.
            Keep the key ideas, remove redundancies, and avoid adding new information.
            Return the summary in one short paragraph.
            Do not include any introductory phrases. Return ONLY the summary text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .proofreading:
            return """
            Proofread the following text. Fix grammar, spelling, punctuation, and syntax errors.
            Preserve the original meaning and style.
            Return ONLY the corrected text without explanations.

            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteFormal:
            return """
            Rewrite the following text in a formal, professional tone.
            Preserve the original meaning, improve clarity and grammar,
            and remove casual expressions or slang.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteCasual:
            return """
            Rewrite the following text in a casual, friendly tone.
            Preserve the original meaning, use conversational language,
            and make it more approachable.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        case .rewriteConcise:
            return """
            Rewrite the following text to be more concise and direct.
            Remove unnecessary words while preserving all key information.
            Return only the rewritten text.
            Do not include any introductory phrases. Return ONLY the rewritten text.
            Text:
            \"\"\"
            \(text)
            \"\"\"
            """
        }
    }

    var title: String {
        switch self {
        case .summarize:
            return "Resumir Texto"
        case .proofreading:
            return "Corregir Texto"
        case .rewriteFormal:
            return "Reescribir Formal"
        case .rewriteCasual:
            return "Reescribir Casual"
        case .rewriteConcise:
            return "Reescribir Conciso"
        }
    }
}
