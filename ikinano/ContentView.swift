//
//  ContentView.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var viewModel = MainViewModel()
    @State private var showInferenceView: Bool = false
    
    @Environment(\.modelContext) private var modelContext

    private var blockingErrorMessage: String? {
        if case .error(let message) = viewModel.state {
            return message
        }

        return nil
    }

    var body: some View {
        ZStack {
            MainMenuView(viewModel: viewModel) { capability in
                viewModel.selectedCapability = capability
                showInferenceView.toggle()
            }
            .sheet(isPresented: $showInferenceView) {
                if let capability = viewModel.selectedCapability {
                    InferenceView(capability: capability, viewModel: viewModel)
                }
            }
            .onAppear {
                // Ensure default models are loaded into SwiftData
                let repo = LLMModelRepository(modelContext: modelContext)
                try? repo.loadDefaultModelsIfNeeded()
            }

            if let message = blockingErrorMessage {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ErrorView(message: message) {
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
