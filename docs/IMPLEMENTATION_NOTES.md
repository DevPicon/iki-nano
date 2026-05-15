# LiteRT-LM Integration: Technical Implementation Notes

This document summarizes the key architectural decisions, implementation details, and technical highlights for the integration of the **Gemma 4 E2B** model via the **LiteRT-LM** framework into the `iki-nano` iOS application.

## 🏗 Architectural Foundation

### 1. Multi-Engine Abstraction
To support both the legacy **MediaPipe** (Gemma 2B) and the new **LiteRT-LM** (Gemma 4), we introduced a protocol-oriented architecture:
*   **`LLMInferenceEngine` Protocol**: A unified interface for model initialization, blocking inference, and asynchronous streaming.
*   **`LLMInferenceEngineFactory`**: Dynamically instantiates the correct engine based on the model's metadata (`engineKind`).
*   **Prompt Policy**: Shifted prompt formatting responsibility from the UI/ViewModel to the engine layer. MediaPipe continues to use manual Gemma turn-tokens, while LiteRT-LM uses role-based JSON to leverage model-owned Jinja templates.

### 2. The Objective-C++ Bridge
Since the LiteRT-LM Swift SDK is currently in development, we implemented a robust bridge to access the stable C++ API:
*   **`LiteRTLMRunner` (C++)**: A RAII wrapper that manages the lifecycle of the LiteRT-LM `Engine` and `Conversation` objects.
*   **`LiteRTLMBridge` (Obj-C++)**: Bridges C++ types (`std::string`) to Objective-C/Swift types (`NSString`) and handles thread-safe dispatching of streaming tokens back to the Main Actor.

## 🛠 SDK Build & Integration

### 1. Building from Source
Instead of using a pre-compiled binary, we built the LiteRT-LM C engine from source using **Bazel**:
*   **Multi-Architecture**: Built for `ios_arm64` (Physical Devices) and `ios_sim_arm64` (Apple Silicon Simulators).
*   **XCFramework**: Packaged the resulting static libraries (`.a`) and headers into a unified `LiteRTLM.xcframework` for seamless Xcode integration.

### 2. Xcode Hardening
Several "pro-level" configurations were required for successful deployment:
*   **`-all_load` Linker Flag**: Essential for LiteRT-LM, as the framework relies on C++ static initializers to register its CPU and Metal (GPU) backends.
*   **C++ Interoperability**: Enabled `objcxx` mode in Swift to allow direct interaction with the Objective-C++ bridge.

## 🚀 Key Technical Highlights

*   **Streaming Inference**: Implemented `SendMessageAsync` using C callbacks bridged to Swift's `withCheckedThrowingContinuation`. This provides a "typewriter" effect in the UI without blocking the main thread.
*   **Metadata-Driven Validation**: The `ModelFileService` was hardened to validate downloads using **SHA-256 checksums** and expected file sizes, critical for the large (2.6GB) Gemma 4 model.
*   **Unified Error System**: Created a centralized `LLMError` enum that maps low-level C++ status codes to localized, user-facing error messages.
*   **Memory Management**: Implemented explicit `unload` and `reset` behaviors to ensure that heavy model weights are purged from RAM when switching between Gemma 2B and Gemma 4.

## 📊 Performance Expectations (iPhone 17 Pro)
*   **Model Size**: ~2.59 GB (.litertlm format).
*   **Throughput**: ~56 tokens/sec on GPU / ~25 tokens/sec on CPU.
*   **TTFT (Time to First Token)**: ~0.3s on GPU / ~1.9s on CPU.

## 📝 Demo Notes
When demonstrating the app, highlight:
1.  **Dynamic Switching**: Show the app switching between a .bin model (MediaPipe) and a .litertlm model (LiteRT-LM) without a restart.
2.  **Streaming Feedback**: Notice how the LiteRT-LM engine starts responding almost instantly thanks to the C++ async runner.
3.  **Metrics Integration**: After inference, show the Metrics View to prove that the engine kind, backend, and load times are being tracked accurately for comparison.

---
**Branch:** `feat/litert-lm-bridge`  
**Date:** May 13, 2026
