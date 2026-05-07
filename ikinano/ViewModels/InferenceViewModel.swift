import Foundation
import Observation

@MainActor
@Observable
final class InferenceViewModel {
    let capability: InferenceCapability

    var inputText: String = ""
    var outputText: String = ""
    var metrics: InferenceMetrics?
    var isProcessing: Bool = false
    var errorMessage: String?
    var selectedTestCase: TestCase?

    private let inferenceService: LLMInferenceService
    private var inferenceTask: Task<Void, Never>?

    init(capability: InferenceCapability, inferenceService: LLMInferenceService) {
        self.capability = capability
        self.inferenceService = inferenceService
    }

    func loadTestCase(_ testCase: TestCase) {
        selectedTestCase = testCase
        inputText = testCase.inputText
    }

    func clear() {
        cancelInference()
        inputText = ""
        outputText = ""
        metrics = nil
        errorMessage = nil
        selectedTestCase = nil
    }

    func cancelInference() {
        inferenceTask?.cancel()
        inferenceTask = nil
        inferenceService.cancelActiveGeneration()
        isProcessing = false
    }

    func runInference() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        cancelInference()
        isProcessing = true
        errorMessage = nil
        outputText = ""
        metrics = nil

        let formattedPrompt = capability.buildPrompt(with: trimmedInput)

        inferenceTask = Task { [weak self] in
            guard let self else { return }

            do {
                let inferenceMetrics = try await inferenceService.generateResponseWithMetrics(
                    capability: capability,
                    inputText: trimmedInput,
                    prompt: formattedPrompt
                ) { cumulativeText in
                    Task { @MainActor in
                        guard !Task.isCancelled else { return }
                        if !cumulativeText.isEmpty {
                            self.outputText = cumulativeText
                        }
                    }
                }

                guard !Task.isCancelled else { return }

                if !inferenceMetrics.outputText.isEmpty {
                    outputText = inferenceMetrics.outputText
                }
                metrics = inferenceMetrics
                isProcessing = false
                inferenceTask = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Inference failed: \(error.localizedDescription)"
                isProcessing = false
                inferenceTask = nil
            }
        }
    }
}
