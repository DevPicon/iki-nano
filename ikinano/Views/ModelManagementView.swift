import SwiftUI
import SwiftData

struct ModelManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LLMModel.name) private var models: [LLMModel]
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: MainViewModel
    
    @State private var showingAddSheet = false
    @State private var newModelName = ""
    @State private var newModelURL = ""
    @State private var newModelFilename = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(models) { model in
                    ModelRowView(model: model, viewModel: viewModel)
                        .swipeActions(edge: .trailing) {
                            if model.isCustom {
                                Button(role: .destructive) {
                                    deleteModel(model)
                                } label: {
                                    Label("Eliminar registro", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .navigationTitle("Modelos de IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Añadir Modelo Customizado")) {
                            TextField("Nombre del Modelo (ej. Gemma 4)", text: $newModelName)
                            TextField("URL (HuggingFace, etc.)", text: $newModelURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            TextField("Nombre de archivo (ej. model.bin)", text: $newModelFilename)
                                .autocapitalization(.none)
                        }
                    }
                    .navigationTitle("Nuevo Modelo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { showingAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
                                addModel()
                                showingAddSheet = false
                            }
                            .disabled(newModelName.isEmpty || newModelURL.isEmpty || newModelFilename.isEmpty)
                        }
                    }
                }
            }
        }
    }
    
    private func addModel() {
        let repo = LLMModelRepository(modelContext: modelContext)
        try? repo.addModel(name: newModelName, urlString: newModelURL, localFilename: newModelFilename)
        newModelName = ""
        newModelURL = ""
        newModelFilename = ""
    }
    
    private func deleteModel(_ model: LLMModel) {
        if model.isDownloaded {
            _ = viewModel.modelFileService.deleteModel(model)
        }
        if viewModel.activeModel?.id == model.id {
            viewModel.activeModel = nil
            viewModel.state = .idle
        }
        let repo = LLMModelRepository(modelContext: modelContext)
        try? repo.removeModel(model)
    }
}

struct ModelRowView: View {
    let model: LLMModel
    @Bindable var viewModel: MainViewModel
    
    @State private var downloadProgress: Double?
    @State private var isDownloading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.name)
                    .font(.headline)
                if model.isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                Spacer()
                
                if viewModel.activeModel?.id == model.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(model.urlString)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            HStack {
                if model.isDownloaded {
                    Text("Descargado")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button("Seleccionar") {
                        viewModel.activeModel = model
                        Task {
                            await viewModel.continueToInference()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.activeModel?.id == model.id)
                    
                    Button(role: .destructive, action: {
                        _ = viewModel.modelFileService.deleteModel(model)
                        if viewModel.activeModel?.id == model.id {
                            viewModel.activeModel = nil
                            viewModel.state = .idle
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                } else if isDownloading {
                    ProgressView(value: downloadProgress ?? 0.0, total: 1.0)
                        .progressViewStyle(.linear)
                    
                    Button(role: .destructive, action: {
                        viewModel.modelFileService.cancelDownload(for: model)
                        isDownloading = false
                        downloadProgress = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                } else {
                    Text("No descargado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Descargar") {
                        isDownloading = true
                        downloadProgress = 0.0
                        viewModel.modelFileService.downloadModel(model, onProgress: { progress in
                            self.downloadProgress = progress
                        }, onCompletion: { result in
                            self.isDownloading = false
                            self.downloadProgress = nil
                        })
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
