- # Technical Documentation: Application Architecture & Execution Flow

  This document details the multi-engine architecture and execution flow of the **Iki Nano** application, specifically focusing on how the app handles dynamic model switching between MediaPipe and LiteRT-LM.

  ## 1. High-Level Architecture

  The application follows a **Decoupled MVVM (Model-ViewModel-View)** pattern. The key innovation is the **Inference Engine Abstraction**, which allows the UI to remain agnostic of the underlying ML framework.

  ```mermaid
  graph TD
    subgraph UI_Layer [UI Layer - SwiftUI]
        MenuView[MainMenuView]
        InferenceV[InferenceView]
        MgmtView[ModelManagementView]
    end

    subgraph ViewModel_Layer [ViewModel Layer]
        MainVM[MainViewModel]
        MetricsVM[MetricsViewModel]
    end

    subgraph Service_Layer [Service Layer]
        Factory[LLMInferenceEngineFactory]
        EngineProtocol[LLMInferenceEngine Protocol]
        MediaPipe[MediaPipeInferenceEngine]
        LiteRTLM[LiteRTLMInferenceEngine]
        FileService[ModelFileService]
    end

    subgraph Bridge_Layer [C++ Bridge]
        Bridge[LiteRTLMBridge Obj-C++]
        Runner[LiteRTLMRunner C++]
    end

    MenuView --> MainVM
    InferenceV --> MainVM
    MgmtView --> MainVM
    
    MainVM --> Factory
    Factory --> EngineProtocol
    EngineProtocol --> LiteRTLM
    EngineProtocol --> MediaPipe
    
    LiteRTLM --> Bridge
    Bridge --> Runner
    MainVM --> FileService
  ```

  ---

  ## 2. The Engine Initialization Flow

  When a user selects a model in the `ModelManagementView`, the following sequence occurs:

  1.  **Selection**: The `activeModel` is updated in `MainViewModel`.
  2.  **Factory Check**: `MainViewModel` calls `LLMInferenceEngineFactory.makeEngine(for: activeModel)`.
  3.  **Engine Swap**: If the engine type changes (e.g., from MediaPipe to LiteRT-LM), the previous engine is deallocated to free up memory.
  4.  **Loading**: The new engine's `initialize(model:modelPath:)` method is called.
      *   **MediaPipe**: Loads the `.bin` weights directly using the GenAI SDK.
      *   **LiteRT-LM**: Initializes the C++ `Engine` and `Conversation` via the Objective-C++ bridge.
  5.  **Ready State**: The `AppState` transitions to `.ready`, enabling the capabilities menu.

  ---

  ## 3. Inference Execution Flow (Streaming)

  The inference flow is standardized across all engines, ensuring a consistent "typewriter" effect in the UI.

  ```mermaid
  sequenceDiagram
    participant User
    participant View as InferenceView
    participant VM as MainViewModel
    participant Proto as LLMInferenceEngine
    participant JSON as JSON Parser
    participant SDK as ML Framework (SDK)

    User->>View: Tap "Run Inference"
    View->>VM: runInference(text)
    VM->>Proto: generateResponseStream(prompt)
    
    loop Token Generation
        SDK->>Proto: Partial Chunk (Raw)
        alt is LiteRT-LM
            Proto->>JSON: Parse Chunk
            JSON-->>Proto: Clean Text
        end
        Proto-->>VM: Update Partial String
        VM-->>View: Refresh UI
    end
    
    SDK-->>Proto: Completion
    Proto-->>VM: Final Metrics
    VM-->>View: Display Performance Card
  ```

  ---

  ## 4. Model Integrity & Validation

  Critical for the 2.6GB Gemma 4 model, the `ModelFileService` implements a strict validation gate:

  1.  **Download**: Standard `URLSessionDownloadTask`.
  2.  **Size Check**: Preliminary verification to catch failed/HTML responses.
  3.  **Checksum**: A full SHA-256 scan is performed.
  4.  **Persistence**: If valid, the `isDownloadedPersistent` flag is set in SwiftData, triggering a reactive UI update.

  ---

  ## 5. Summary of Key Decisions

  - **Symbol Isolation**: LiteRT-LM internal symbols are hidden using a linker export list to prevent collisions with MediaPipe's internal Google dependencies.
  - **JSON Adapters**: The engine layer is responsible for converting SDK-specific formats (like LiteRT-LM's structured JSON) into plain text before it reaches the ViewModel.
  - **Reactive State**: The app uses stored persistent flags instead of file-system polling to ensure the UI is always in sync with the download status.
