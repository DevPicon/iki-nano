//
//  ModelFileService.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation

/// Service responsible for downloading and managing the Gemma model file
final class ModelFileService: NSObject {
    // Model URL and filename are configured in Config.swift
    // See Config.swift.example for setup instructions
    private let modelURL = URL(string: AppConfig.modelURL)!
    private let modelFileName = AppConfig.modelFileName

    // Minimum expected file size (1.3 GB - Gemma 2B int4 quantized)
    // The actual model is ~1.35 GB
    private let minimumFileSize: Int64 = 1_300_000_000

    private var downloadTask: URLSessionDownloadTask?
    private var urlSession: URLSession!

    /// Progress callback (0.0 to 1.0)
    var onProgress: ((Double) -> Void)?

    /// Completion callback with file URL or error
    var onCompletion: ((Result<URL, Error>) -> Void)?

    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    /// Returns the path where the model file should be stored
    var modelFilePath: URL {
        // First check if model is in the app bundle (recommended approach)
        if let bundlePath = Bundle.main.url(forResource: "gemma-2b-it-gpu-int4", withExtension: "bin") {
            return bundlePath
        }

        // Fallback to Documents directory
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(modelFileName)
    }

    /// Check if the model file already exists (in bundle or downloaded)
    func isModelDownloaded() -> Bool {
        // Check bundle first
        if let bundlePath = Bundle.main.url(forResource: "gemma-2b-it-gpu-int4", withExtension: "bin"),
           FileManager.default.fileExists(atPath: bundlePath.path) {
            return true
        }

        // Check Documents directory with size validation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(modelFileName)

        guard FileManager.default.fileExists(atPath: documentsPath.path) else {
            return false
        }

        // Validate file size to ensure it's not corrupted
        if let attributes = try? FileManager.default.attributesOfItem(atPath: documentsPath.path),
           let fileSize = attributes[.size] as? Int64 {
            return fileSize >= minimumFileSize
        }

        return false
    }

    /// Start downloading the model
    func downloadModel() {
        guard !isModelDownloaded() else {
            // Model already exists, return success
            onCompletion?(.success(modelFilePath))
            return
        }

        downloadTask = urlSession.downloadTask(with: modelURL)
        downloadTask?.resume()
    }

    /// Cancel the ongoing download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
    }

    /// Delete the downloaded model file
    /// - Returns: Result with success or error
    func deleteModel() -> Result<Void, Error> {
        // Cannot delete model from app bundle
        if let bundlePath = Bundle.main.url(forResource: "gemma-2b-it-gpu-int4", withExtension: "bin"),
           FileManager.default.fileExists(atPath: bundlePath.path) {
            return .failure(ModelFileError.cannotDeleteBundledModel)
        }

        // Delete from Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(modelFileName)

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
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { [weak self] in
            self?.onProgress?(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // Validate file size before moving
            let attributes = try FileManager.default.attributesOfItem(atPath: location.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            if fileSize < minimumFileSize {
                throw ModelFileError.fileTooSmall(size: fileSize, expected: minimumFileSize)
            }

            // Move the downloaded file to the documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(modelFileName)

            if FileManager.default.fileExists(atPath: documentsPath.path) {
                try FileManager.default.removeItem(at: documentsPath)
            }
            try FileManager.default.moveItem(at: location, to: documentsPath)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onCompletion?(.success(documentsPath))
            }
        } catch {
            // Clean up any corrupted file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(modelFileName)
            try? FileManager.default.removeItem(at: documentsPath)

            DispatchQueue.main.async { [weak self] in
                self?.onCompletion?(.failure(error))
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.onCompletion?(.failure(error))
            }
        }
    }
}

// MARK: - Errors
enum ModelFileError: LocalizedError {
    case fileTooSmall(size: Int64, expected: Int64)
    case modelNotFound
    case cannotDeleteBundledModel

    var errorDescription: String? {
        switch self {
        case .fileTooSmall(let size, let expected):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let sizeStr = formatter.string(fromByteCount: size)
            let expectedStr = formatter.string(fromByteCount: expected)
            return "El archivo descargado es demasiado pequeño (\(sizeStr)). Se esperaban al menos \(expectedStr). La descarga falló o la URL es incorrecta."
        case .modelNotFound:
            return "El modelo no se encontró en el dispositivo."
        case .cannotDeleteBundledModel:
            return "No se puede eliminar un modelo incluido en la aplicación."
        }
    }
}
