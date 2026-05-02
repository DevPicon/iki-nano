//
//  InferenceView.swift
//  ikinano
//

import SwiftUI

struct InferenceView: View {
    let capability: InferenceCapability
    @Bindable var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var metrics: InferenceMetrics?
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @State private var showTestDataSelector: Bool = false
    @State private var selectedTestCase: TestCase?
    @FocusState private var isInputFocused: Bool

    private var availableTestCases: [TestCase] {
        TestDataRepository.getTestCases(for: capability)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Back") {
                    dismiss()
                }
                Spacer()
                Text(capability.displayName)
                    .font(.headline)
                Spacer()
                Button("Back") { dismiss() }.opacity(0) // Balance spacer
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .bottom)

            ScrollView {
                VStack(spacing: 16) {
                    Text(capability.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button(action: {
                            showTestDataSelector = true
                        }) {
                            Label("Load Test Data", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: clearInput) {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Text")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextEditor(text: $inputText)
                            .focused($isInputFocused)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                        Text("\(inputText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isInputFocused = false
                            }
                        }
                    }

                    Button(action: runInference) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "play.fill")
                            }

                            Text(isProcessing ? "Processing..." : "Run Inference")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputText.isEmpty || isProcessing)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    if !outputText.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Output")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = outputText
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }

                            Text(outputText)
                                .font(.body)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }

                    if let metrics = metrics {
                        Divider()
                            .padding(.vertical, 8)

                        MetricsCard(metrics: metrics)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showTestDataSelector) {
            TestDataSelector(
                testCases: availableTestCases,
                onTestCaseSelected: loadTestCase
            )
        }
        .onAppear {
            print("👁️ InferenceView appeared for \(capability.displayName)")
            // Force a UI refresh if needed
            errorMessage = nil
        }
    }
}

    private func loadTestCase(_ testCase: TestCase) {
        selectedTestCase = testCase
        inputText = testCase.inputText
    }

    private func clearInput() {
        inputText = ""
        outputText = ""
        metrics = nil
        errorMessage = nil
        selectedTestCase = nil
    }

    private func runInference() {
        isProcessing = true
        errorMessage = nil
        outputText = ""
        metrics = nil
        isInputFocused = false

        Task {
            do {
                let task = capabilityToTask(capability)
                let prompt = task.buildPrompt(with: inputText)
                
                let formattedPrompt = """
                <start_of_turn>user
                \(prompt)<end_of_turn>
                <start_of_turn>model
                """

                let inferenceMetrics = try await viewModel.llmInferenceService.generateResponseWithMetrics(
                    capability: capability,
                    inputText: inputText,
                    prompt: formattedPrompt
                ) { [weak viewModel] cumulativeText in
                    Task { @MainActor in
                        if !cumulativeText.isEmpty {
                            self.outputText = cumulativeText
                        }
                    }
                }

                await MainActor.run {
                    if !inferenceMetrics.outputText.isEmpty {
                        self.outputText = inferenceMetrics.outputText
                    }
                    self.metrics = inferenceMetrics
                    self.isProcessing = false
                    
                    if self.outputText.isEmpty {
                        print("⚠️ Warning: Inference finished but outputText is empty for \(capability.displayName)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Inference failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }

    private func capabilityToTask(_ capability: InferenceCapability) -> InferenceTask {
        switch capability {
        case .summarization: return .summarize
        case .proofreading: return .proofreading
        case .rewriteFormal: return .rewriteFormal
        case .rewriteCasual: return .rewriteCasual
        case .rewriteConcise: return .rewriteConcise
        }
    }
}

#Preview {
    InferenceView(capability: .summarization, viewModel: MainViewModel())
}
