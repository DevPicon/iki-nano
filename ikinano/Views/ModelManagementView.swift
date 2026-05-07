import SwiftUI
import SwiftData

struct ModelManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LLMModel.name) private var models: [LLMModel]
    @Environment(\.dismiss) private var dismiss

    @Bindable var appViewModel: MainViewModel
    @State private var viewModel = ModelManagementViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(models) { model in
                    ModelRowView(
                        model: model,
                        appViewModel: appViewModel,
                        viewModel: viewModel
                    )
                    .swipeActions(edge: .trailing) {
                        if model.isCustom {
                            Button(role: .destructive) {
                                viewModel.deleteModelRecord(model)
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
                    Button(action: viewModel.presentAddSheet) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Añadir Modelo Customizado")) {
                            TextField("Nombre del Modelo (ej. Gemma 4)", text: $viewModel.newModelName)
                            TextField("URL (HuggingFace, etc.)", text: $viewModel.newModelURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            TextField("Nombre de archivo (ej. model.bin)", text: $viewModel.newModelFilename)
                                .autocapitalization(.none)
                        }
                    }
                    .navigationTitle("Nuevo Modelo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar", action: viewModel.dismissAddSheet)
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar", action: viewModel.saveNewModel)
                                .disabled(!viewModel.canSaveNewModel)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext, appViewModel: appViewModel)
            }
        }
    }
}

struct ModelRowView: View {
    let model: LLMModel
    @Bindable var appViewModel: MainViewModel
    @Bindable var viewModel: ModelManagementViewModel

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

                if appViewModel.activeModel?.id == model.id {
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
                        viewModel.selectModel(model)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appViewModel.activeModel?.id == model.id)

                    Button(role: .destructive) {
                        viewModel.deleteDownloadedModel(model)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                } else if viewModel.isDownloading(model) {
                    ProgressView(value: viewModel.downloadProgress(for: model), total: 1.0)
                        .progressViewStyle(.linear)

                    Button(role: .destructive) {
                        viewModel.cancelDownload(for: model)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                } else {
                    Text("No descargado")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Descargar") {
                        viewModel.startDownload(for: model)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
