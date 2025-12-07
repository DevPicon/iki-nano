//
//  DownloadView.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import SwiftUI

struct DownloadView: View {
    let state: AppState
    let isModelDownloaded: Bool
    let onDownload: () -> Void
    let onContinue: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            // Title
            Text("Gemma 2B On-Device")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Modelo de IA que funciona completamente offline")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Download button, Continue button, or progress
            if case .initializing = state {
                // Model is initializing
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.green)

                    Text("Cargando modelo en memoria...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
            } else if case .deleting = state {
                // Model is deleting
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.red)

                    Text("Eliminando modelo...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
            } else if case .downloading(let progress) = state {
                VStack(spacing: 16) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)

                    Text("Descargando modelo... \(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(formatBytes(progress * 1.4 * 1024 * 1024 * 1024)) / 1.4 GB")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 40)
            } else if isModelDownloaded {
                // Model is downloaded, show Continue and Delete buttons
                VStack(spacing: 16) {
                    Text("✓ Modelo descargado")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)

                    Button(action: onContinue) {
                        Label("Continuar", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.gradient)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Eliminar modelo", systemImage: "trash.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                .alert("Eliminar Modelo", isPresented: $showingDeleteConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Eliminar", role: .destructive) {
                        onDelete()
                    }
                } message: {
                    Text("¿Estás seguro de que quieres eliminar el modelo descargado? Tendrás que descargarlo nuevamente para usarlo (1.4 GB).")
                }
            } else {
                // Model not downloaded, show Download button
                Button(action: onDownload) {
                    Label("Descargar Cerebro (1.4 GB)", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding()
    }

    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview("Not Downloaded") {
    DownloadView(state: .idle, isModelDownloaded: false) {
        print("Download tapped")
    } onContinue: {
        print("Continue tapped")
    } onDelete: {
        print("Delete tapped")
    }
}

#Preview("Downloaded") {
    DownloadView(state: .idle, isModelDownloaded: true) {
        print("Download tapped")
    } onContinue: {
        print("Continue tapped")
    } onDelete: {
        print("Delete tapped")
    }
}

#Preview("Downloading") {
    DownloadView(state: .downloading(progress: 0.65), isModelDownloaded: false) {
        print("Download tapped")
    } onContinue: {
        print("Continue tapped")
    } onDelete: {
        print("Delete tapped")
    }
}
