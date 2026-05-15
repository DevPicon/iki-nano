//
//  Config.swift
//  ikinano
//
//  Configuration file for application-wide settings and feature flags.
//

import Foundation

enum AppConfig {
    // MARK: - Feature Flags
    
    /// Enable the LiteRT-LM inference engine
    static let enableLiteRTLM = true
    
    /// Enable GPU support for LiteRT-LM (CPU fallback if disabled or unsupported)
    static let enableLiteRTLMGPU = false
    
    /// Enable Multi-Token Prediction / Speculative Decoding for Gemma 4
    static let enableSpeculativeDecoding = true
    
    // MARK: - Default Model Settings (Legacy/Fallback)
    
    /// URL to download the Gemma 2B model
    static let modelURL = "https://huggingface.co/devpicon/gemma-2b-ios/resolve/main/gemma-2b-it-gpu-int4.bin"

    /// Model file name
    static let modelFileName = "gemma-2b-it-gpu-int4.bin"
}
