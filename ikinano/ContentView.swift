//
//  ContentView.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MainViewModel()
    @State private var selectedCapability: InferenceCapability?
    @State private var showInferenceView: Bool = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .downloading, .initializing, .deleting:
                DownloadView(
                    state: viewModel.state,
                    isModelDownloaded: viewModel.isModelDownloaded()
                ) {
                    viewModel.downloadModel()
                } onContinue: {
                    Task {
                        await viewModel.continueToInference()
                    }
                } onDelete: {
                    viewModel.deleteModel()
                }

            case .ready, .processing:
                MainMenuView { capability in
                    selectedCapability = capability
                    showInferenceView = true
                }
                .sheet(isPresented: $showInferenceView) {
                    if let capability = selectedCapability {
                        InferenceView(capability: capability, viewModel: viewModel)
                    }
                }

            case .error(let message):
                ErrorView(message: message) {
                    // Reset to idle state to allow retry
                    viewModel.state = .idle
                }
            }

        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Error")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onRetry) {
                Text("Reintentar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
