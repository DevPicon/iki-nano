//
//  ModelFileService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation

/// Service responsible for downloading and managing LLM model files
final class ModelFileService: NSObject {
    private var urlSession: URLSession!
    
    // Track active downloads by their task to allow multiple concurrent downloads
    private var activeDownloads: [Int: DownloadState] = [:]
    
    struct DownloadState {
        let model: LLMModel
        let onProgress: (Double) -> Void
        let onCompletion: (Result<URL, Error>) -> Void
    }
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    /// Returns the path where the model file should be stored
    func modelFilePath(for model: LLMModel) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(model.localFilename)
    }
    
    /// Check if the model file already exists
    func isModelDownloaded(model: LLMModel) -> Bool {
        return model.isDownloaded
    }
    
    /// Start downloading the model
    func downloadModel(_ model: LLMModel, onProgress: @escaping (Double) -> Void, onCompletion: @escaping (Result<URL, Error>) -> Void) {
        guard !isModelDownloaded(model: model) else {
            onCompletion(.success(modelFilePath(for: model)))
            return
        }
        
        guard let url = model.url else {
            onCompletion(.failure(ModelFileError.invalidURL))
            return
        }
        
        let task = urlSession.downloadTask(with: url)
        activeDownloads[task.taskIdentifier] = DownloadState(model: model, onProgress: onProgress, onCompletion: onCompletion)
        task.resume()
    }
    
    /// Cancel the ongoing download for a specific model
    func cancelDownload(for model: LLMModel) {
        if let (taskIdentifier, _) = activeDownloads.first(where: { $0.value.model.id == model.id }) {
            urlSession.getAllTasks { tasks in
                if let task = tasks.first(where: { $0.taskIdentifier == taskIdentifier }) {
                    task.cancel()
                }
            }
            activeDownloads.removeValue(forKey: taskIdentifier)
        }
    }
    
    /// Delete the downloaded model file
    func deleteModel(_ model: LLMModel) -> Result<Void, Error> {
        let documentsPath = modelFilePath(for: model)
        
        guard FileManager.default.fileExists(atPath: documentsPath.path) else {
            return .failure(ModelFileError.modelNotFound)
        }
        
        do {
            try FileManager.default.removeItem(at: documentsPath)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension ModelFileService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let state = activeDownloads[downloadTask.taskIdentifier] else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            state.onProgress(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let state = activeDownloads[downloadTask.taskIdentifier] else { return }
        
        do {
            let destinationURL = modelFilePath(for: state.model)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                state.onCompletion(.success(destinationURL))
            }
        } catch {
            DispatchQueue.main.async {
                state.onCompletion(.failure(error))
            }
        }
        
        activeDownloads.removeValue(forKey: downloadTask.taskIdentifier)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let state = activeDownloads[task.taskIdentifier] else { return }
        
        if let error = error {
            DispatchQueue.main.async {
                state.onCompletion(.failure(error))
            }
            activeDownloads.removeValue(forKey: task.taskIdentifier)
        }
    }
}

// MARK: - Errors
enum ModelFileError: LocalizedError {
    case invalidURL
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL del modelo no es válida."
        case .modelNotFound:
            return "El modelo no se encontró en el dispositivo."
        }
    }
}
