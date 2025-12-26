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
        NavigationView {
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
            .navigationTitle(capability.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                }
            }
            .sheet(isPresented: $showTestDataSelector) {
                TestDataSelector(
                    testCases: availableTestCases,
                    onTestCaseSelected: loadTestCase
                )
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

        Task {
            do {
                let task = capabilityToTask(capability)
                let inferenceMetrics = try await viewModel.llmInferenceService.generateResponseWithMetrics(
                    capability: capability,
                    inputText: inputText,
                    prompt: task.buildPrompt(with: inputText)
                )

                await MainActor.run {
                    outputText = inferenceMetrics.outputText
                    metrics = inferenceMetrics
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Inference failed: \(error.localizedDescription)"
                    isProcessing = false
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
