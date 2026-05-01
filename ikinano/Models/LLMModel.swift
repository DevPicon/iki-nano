import Foundation
import SwiftData

@Model
class LLMModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var urlString: String
    var localFilename: String
    var isCustom: Bool
    
    @Transient var isDownloaded: Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(localFilename)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    var url: URL? {
        URL(string: urlString)
    }
    
    init(id: UUID = UUID(), name: String, urlString: String, localFilename: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.localFilename = localFilename
        self.isCustom = isCustom
    }
}