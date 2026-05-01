//
//  Config.swift.example
//  ikinano
//
//  Configuration file for local development settings
//
//  INSTRUCTIONS:
//  1. Copy this file and rename it to "Config.swift" (without .example)
//  2. Update the modelURL with your own Hugging Face model URL
//  3. The Config.swift file will not be committed to git
//

import Foundation

enum AppConfig {
    /// URL to download the Gemma model
    /// Replace this with your own Hugging Face model URL
    /// Example: https://huggingface.co/YOUR_USERNAME/YOUR_MODEL/resolve/main/model.bin
    static let modelURL = "https://huggingface.co/devpicon/gemma-2b-ios/resolve/main/gemma-2b-it-gpu-int4.bin"

    /// Model file name (should match the file in the URL)
    static let modelFileName = "gemma-2b-it-gpu-int4.bin"
}
