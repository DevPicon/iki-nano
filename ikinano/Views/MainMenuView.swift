//
//  MainMenuView.swift
//  ikinano
//

import SwiftUI

struct MainMenuView: View {
    @Bindable var viewModel: MainViewModel
    let onCapabilitySelected: (InferenceCapability) -> Void
    
    @State private var showingModelManagement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Iki Nano")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("On-device AI with Gemma")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                    // Active Model Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Modelo Activo")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingModelManagement = true
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    if let activeModel = viewModel.activeModel {
                                        Text(activeModel.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(activeModel.isCustom ? "Customizado" : "Por defecto")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Ningún modelo seleccionado")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        Text("Toca para gestionar modelos")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.activeModel != nil {
                            if case .initializing = viewModel.state {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Inicializando modelo en memoria...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            } else if case .ready = viewModel.state {
                                Text("Modelo cargado y listo para inferencia")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal)
                            } else {
                                Text("Modelo no inicializado")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    Divider()
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        CapabilityCard(
                            capability: .summarization,
                            icon: "doc.text.fill",
                            onTap: { onCapabilitySelected(.summarization) }
                        )

                        CapabilityCard(
                            capability: .proofreading,
                            icon: "text.badge.checkmark",
                            onTap: { onCapabilitySelected(.proofreading) }
                        )

                        CapabilityCard(
                            capability: .rewriteFormal,
                            icon: "text.badge.star",
                            onTap: { onCapabilitySelected(.rewriteFormal) }
                        )

                        CapabilityCard(
                            capability: .rewriteCasual,
                            icon: "text.bubble.fill",
                            onTap: { onCapabilitySelected(.rewriteCasual) }
                        )

                        CapabilityCard(
                            capability: .rewriteConcise,
                            icon: "text.alignleft",
                            onTap: { onCapabilitySelected(.rewriteConcise) }
                        )
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.state != .ready)
                    .opacity(viewModel.state != .ready ? 0.5 : 1.0)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingModelManagement) {
                ModelManagementView(appViewModel: viewModel)
            }
        }
    }
}

struct CapabilityCard: View {
    let capability: InferenceCapability
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(capability.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(capability.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainMenuView(viewModel: MainViewModel(), onCapabilitySelected: { _ in })
}
