//
//  InferenceView.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import SwiftUI

struct InferenceView: View {
    @Bindable var viewModel: MainViewModel

    @State private var inputText: String = ""
    @State private var selectedTask: InferenceTask = .summarize
    @FocusState private var isInputFocused: Bool

    private var isProcessing: Bool {
        if case .processing = viewModel.state {
            return true
        }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                ZStack(alignment: .topLeading) {
                    // Back Button
                    Button(action: {
                        viewModel.state = .idle
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .padding(.leading)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .font(.system(size: 40))
                            .foregroundStyle(.green.gradient)
                        
                        Text("Gemma 2B Ready")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("100% Offline • On-Device AI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top)
                
                // Task Selector
                Picker("Tarea", selection: $selectedTask) {
                    Text(InferenceTask.summarize.title).tag(InferenceTask.summarize)
                    Text(InferenceTask.rewriteFormal.title).tag(InferenceTask.rewriteFormal)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Input Text Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Texto de entrada:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $inputText)
                        .focused($isInputFocused)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Execute Button
                Button(action: {
                    Task {
                        await viewModel.runTaskInference(task: selectedTask, text: inputText)
                    }
                }) {
                    HStack {
                        if case .processing = viewModel.state {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        
                        if case .processing = viewModel.state {
                            Text("Procesando...")
                        } else {
                            Text("Ejecutar")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray.gradient : Color.green.gradient)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(inputText.isEmpty || isProcessing)
                .padding(.horizontal)
                
                // Response Section
                if !viewModel.generatedResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Respuesta:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = viewModel.generatedResponse
                            }) {
                                Label("Copiar", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        
                        ScrollView {
                            Text(viewModel.generatedResponse)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .onTapGesture {
                isInputFocused = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        isInputFocused = false
                        viewModel.state = .idle
                    }
                }
            }
        }
    }
}

#Preview {
    InferenceView(viewModel: MainViewModel())
}
