//
//  ModelFileService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation
import CryptoKit

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
        
        print("ModelFileService: Download finished to temporary location: \(location)")
        
        do {
            print("ModelFileService: Validating file for \(state.model.name)...")
            try validateDownloadedFile(at: location, for: state.model)
            print("ModelFileService: Validation successful.")

            let destinationURL = modelFilePath(for: state.model)
            print("ModelFileService: Moving file to: \(destinationURL.path)")
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            print("ModelFileService: File moved successfully.")
            DispatchQueue.main.async {
                state.onCompletion(.success(destinationURL))
            }
        } catch {
            print("ModelFileService: ERROR during validation/move: \(error.localizedDescription)")
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
    case invalidModelFormat(expected: String)
    case invalidModelSize(expected: Int64, actual: Int64)
    case checksumMismatch(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL del modelo no es válida."
        case .modelNotFound:
            return "El modelo no se encontró en el dispositivo."
        case .invalidModelFormat(let expected):
            return "El archivo descargado no tiene el formato esperado: \(expected)."
        case .invalidModelSize(let expected, let actual):
            return "El tamaño del modelo no coincide. Esperado: \(expected) bytes. Recibido: \(actual) bytes."
        case .checksumMismatch(let expected, let actual):
            return "La verificación SHA-256 falló. Esperado: \(expected). Recibido: \(actual)."
        }
    }
}

private extension ModelFileService {
    func validateDownloadedFile(at location: URL, for model: LLMModel) throws {
        try validateFormat(for: model)

        let attributes = try FileManager.default.attributesOfItem(atPath: location.path)
        if let expectedSizeBytes = model.expectedSizeBytes,
           let actualSizeBytes = attributes[.size] as? NSNumber {
            
            // Allow a small tolerance or just check for a minimum threshold (10MB)
            // to catch HTML error pages, but rely on SHA256 for integrity.
            let minimumThreshold: Int64 = 10 * 1024 * 1024 
            if actualSizeBytes.int64Value < minimumThreshold {
                throw ModelFileError.invalidModelSize(
                    expected: expectedSizeBytes,
                    actual: actualSizeBytes.int64Value
                )
            }
        }

        if let expectedSHA256 = model.sha256, !expectedSHA256.isEmpty {
            print("ModelFileService: Starting SHA-256 checksum verification (this may take a few seconds)...")
            let actualSHA256 = try sha256HexDigest(for: location)
            print("ModelFileService: Checksum calculated: \(actualSHA256)")
            
            guard actualSHA256.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
                throw ModelFileError.checksumMismatch(
                    expected: expectedSHA256,
                    actual: actualSHA256
                )
            }
        }
    }

    func validateFormat(for model: LLMModel) throws {
        switch model.modelFormat {
        case .bin:
            guard model.localFilename.hasSuffix(".bin") else {
                throw ModelFileError.invalidModelFormat(expected: ".bin")
            }
        case .litertlm:
            guard model.localFilename.hasSuffix(".litertlm") else {
                throw ModelFileError.invalidModelFormat(expected: ".litertlm")
            }
        }
    }

    func sha256HexDigest(for fileURL: URL) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? fileHandle.close()
        }

        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: 1024 * 1024)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
