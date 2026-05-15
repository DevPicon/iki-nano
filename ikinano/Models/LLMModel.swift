import Foundation
import SwiftData

@Model
class LLMModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var urlString: String
    var localFilename: String
    var isCustom: Bool
    var engineKindRawValue: String = LLMEngineKind.mediaPipe.rawValue
    var backendPreferenceRawValue: String = LLMBackendPreference.automatic.rawValue
    var modelFormatRawValue: String = LLMModelFormat.bin.rawValue
    var supportsStreaming: Bool = true
    var supportsSpeculativeDecoding: Bool = false
    var expectedSizeBytes: Int64?
    var sha256: String?
    var defaultContextLength: Int?
    var requiresPromptTemplateFormatting: Bool = true
    var isDownloadedPersistent: Bool = false
    
    @Transient var isDownloaded: Bool {
        // First check the persistent flag (reactive)
        if isDownloadedPersistent { return true }
        
        // Fallback to file system check (for initial state or manual file additions)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(localFilename)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    var url: URL? {
        URL(string: urlString)
    }

    @Transient var engineKind: LLMEngineKind {
        get { LLMEngineKind(rawValue: engineKindRawValue) ?? .mediaPipe }
        set { engineKindRawValue = newValue.rawValue }
    }

    @Transient var backendPreference: LLMBackendPreference {
        get { LLMBackendPreference(rawValue: backendPreferenceRawValue) ?? .automatic }
        set { backendPreferenceRawValue = newValue.rawValue }
    }

    @Transient var modelFormat: LLMModelFormat {
        get { LLMModelFormat(rawValue: modelFormatRawValue) ?? .bin }
        set { modelFormatRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        localFilename: String,
        isCustom: Bool = false,
        engineKind: LLMEngineKind = .mediaPipe,
        backendPreference: LLMBackendPreference = .automatic,
        modelFormat: LLMModelFormat = .bin,
        supportsStreaming: Bool = true,
        supportsSpeculativeDecoding: Bool = false,
        expectedSizeBytes: Int64? = nil,
        sha256: String? = nil,
        defaultContextLength: Int? = nil,
        requiresPromptTemplateFormatting: Bool = true
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.localFilename = localFilename
        self.isCustom = isCustom
        self.engineKindRawValue = engineKind.rawValue
        self.backendPreferenceRawValue = backendPreference.rawValue
        self.modelFormatRawValue = modelFormat.rawValue
        self.supportsStreaming = supportsStreaming
        self.supportsSpeculativeDecoding = supportsSpeculativeDecoding
        self.expectedSizeBytes = expectedSizeBytes
        self.sha256 = sha256
        self.defaultContextLength = defaultContextLength
        self.requiresPromptTemplateFormatting = requiresPromptTemplateFormatting
    }
}
