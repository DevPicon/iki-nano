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
    private let modelFileService = ModelFileService()
    private let llmInferenceService = LLMInferenceService()

    var state: AppState = .idle
    var generatedResponse: String = ""

    // MARK: - Initialization
    init() {
        checkModelAvailability()
    }

    // MARK: - Model Management
    /// Check if model is already downloaded
    private func checkModelAvailability() {
        // Don't auto-initialize, let user choose when to continue
        state = .idle
    }
    
    /// Check if model is downloaded (public for UI)
    func isModelDownloaded() -> Bool {
        return modelFileService.isModelDownloaded()
    }

    /// Initialize the model (called when user taps Continue)
    @MainActor
    func continueToInference() async {
        state = .initializing
        await initializeModel()
    }

    /// Download the Gemma 2B model
    @MainActor
    func downloadModel() {
        guard case .idle = state else { return }

        state = .downloading(progress: 0.0)

        modelFileService.onProgress = { [weak self] progress in
            guard let self = self else { return }
            Task { @MainActor in
                self.state = .downloading(progress: progress)
            }
        }

        modelFileService.onCompletion = { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success:
                    await self.initializeModel()
                case .failure(let error):
                    self.state = .error("Download failed: \(error.localizedDescription)")
                }
            }
        }

        modelFileService.downloadModel()
    }

    /// Initialize the LLM model
    private func initializeModel() async {
        let modelPath = modelFileService.modelFilePath.path

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
        state = .deleting
        
        Task {
            // Add delay for better UX
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let result = modelFileService.deleteModel()

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
    case rewriteFormal

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
        }
    }

    var title: String {
        switch self {
        case .summarize:
            return "Resumir Texto"
        case .rewriteFormal:
            return "Reescribir Formal"
        }
    }
}
