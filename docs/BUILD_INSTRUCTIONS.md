# Build Instructions: LiteRT-LM for iOS

This document explains how to build the LiteRT-LM C++ core from source and integrate it into the `iki-nano` iOS project.

## 🛠 Prerequisites

1.  **Bazel**: The project uses Bazelisk to manage Bazel versions.
    ```bash
    brew install bazelisk
    ```
2.  **Xcode**: Version 15+ with iOS 17.0+ SDK.
3.  **CocoaPods**: For MediaPipe dependencies.

## 🏗 Building the C++ Framework

We build LiteRT-LM as a **Dynamic Framework** to prevent symbol collisions with MediaPipe.

1.  **Clone the LiteRT-LM Repository**:
    ```bash
    git clone https://github.com/google-ai-edge/LiteRT-LM.git
    cd LiteRT-LM
    ```
2.  **Configure the BUILD file**:
    Ensure `c/BUILD` includes the `ios_framework` target with the explicit exports list (see `IMPLEMENTATION_NOTES.md` for details).
3.  **Run the Build**:
    ```bash
    # For Physical Device
    bazel build --config=ios_arm64 //c:LiteRTLM
    
    # For Simulator
    bazel build --config=ios_sim_arm64 //c:LiteRTLM
    ```
4.  **Create the XCFramework**:
    Extract the `.zip` artifacts from `bazel-bin/c/` and bundle them:
    ```bash
    xcodebuild -create-xcframework \
      -framework device/LiteRTLM.framework \
      -framework simulator/LiteRTLM.framework \
      -output LiteRTLM.xcframework
    ```

## 📱 Building the iOS App

1.  **Switch to the feature branch**:
    ```bash
    git checkout feat/litert-lm-bridge
    ```
2.  **Link the Framework**:
    Place `LiteRTLM.xcframework` in the `Frameworks/` directory.
3.  **Configure Xcode**:
    Run the integration script to set up Bridging Headers, C++ Interop, and Linker flags:
    ```bash
    ruby add_litertlm_bridge_to_xcode.rb
    ```
4.  **Install Pods**:
    ```bash
    pod install
    ```
5.  **Run**: Open `ikinano.xcworkspace` and run on an **arm64** target (iPhone 12+ or Apple Silicon Simulator).

## 🧪 Testing the Implementation

1.  **Download the Model**:
    *   Open **Model Management**.
    *   Find **Gemma 4 E2B (LiteRT-LM CPU)**.
    *   Tap **Descargar**. The app will verify the file integrity using SHA-256.
2.  **Select & Run**:
    *   Select the downloaded Gemma 4 model.
    *   Choose a capability (e.g., **Rewrite Casual**).
    *   Observe the **Streaming Response**. The app automatically parses LiteRT-LM's structured JSON output into plain text.
3.  **Verify Metrics**:
    *   After inference, check the metrics view to see the TTFT and total inference time for the LiteRT-LM engine.

## 🔍 How it Works (Under the Hood)

*   **Symbol Isolation**: The dynamic framework uses a linker export list to hide internal Google/Abseil symbols, allowing LiteRT-LM to live alongside MediaPipe without crashes.
*   **Reactive UI**: Uses a persistent database flag (`isDownloadedPersistent`) to ensure the UI updates the moment the 2.6GB file finishes moving to the documents folder.
*   **JSON Adapter**: The `LiteRTLMInferenceEngine` includes a built-in JSON parser that converts the engine's structured chat messages into the flat strings expected by the UI.
