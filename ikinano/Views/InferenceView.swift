//
//  InferenceView.swift
//  ikinano
//

import SwiftUI

struct InferenceView: View {
    let capability: InferenceCapability
    @Environment(\.dismiss) var dismiss

    @State private var showTestDataSelector: Bool = false
    @State private var viewModel: InferenceViewModel
    @FocusState private var isInputFocused: Bool

    private var availableTestCases: [TestCase] {
        TestDataRepository.getTestCases(for: capability)
    }

    init(capability: InferenceCapability, viewModel: MainViewModel) {
        self.capability = capability
        _viewModel = State(initialValue: InferenceViewModel(
            capability: capability,
            inferenceService: viewModel.llmInferenceService
        ))
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
                Button("Back") { dismiss() }.opacity(0)
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
                        Button {
                            showTestDataSelector = true
                        } label: {
                            Label("Load Test Data", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: clearInput) {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Text")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextEditor(text: $viewModel.inputText)
                            .focused($isInputFocused)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .disabled(viewModel.isProcessing)

                        Text("\(viewModel.inputText.count) characters")
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
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "play.fill")
                            }

                            Text(viewModel.isProcessing ? "Processing..." : "Run Inference")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isProcessing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                    .padding(.horizontal)

                    if viewModel.isProcessing {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(.circular)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Generating response...")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("The model is still processing the current request.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    if !viewModel.outputText.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Output")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = viewModel.outputText
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }

                            Text(viewModel.outputText)
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

                    if let metrics = viewModel.metrics {
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
                viewModel.errorMessage = nil
            }
            .onDisappear {
                viewModel.cancelInference()
            }
        }
    }

    private func loadTestCase(_ testCase: TestCase) {
        viewModel.loadTestCase(testCase)
    }

    private func clearInput() {
        viewModel.clear()
    }

    private func runInference() {
        isInputFocused = false
        viewModel.runInference()
    }
}

#Preview {
    InferenceView(capability: .summarization, viewModel: MainViewModel())
}
