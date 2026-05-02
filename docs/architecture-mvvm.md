# Architecture Guidelines: Scalable MVVM with SwiftUI

**Project:** `iki-nano` (iOS)
**Focus:** Scalability, Multi-Model Support (Gemma 2B, Gemma 4 E2B), and Clean Architecture

## 1. Overview
The `iki-nano` application utilizes the **Model-View-ViewModel (MVVM)** architectural pattern combined with **SwiftUI**. The primary goal of this architecture is to separate the user interface from the business logic and the underlying AI inference engine (MediaPipe Tasks GenAI). 

With the introduction of new mobile-optimized models like **Gemma 4 E2B**, the architecture must be scalable and flexible enough to support multiple models dynamically, allowing seamless swapping of the underlying inference engine or model weights without affecting the UI layer.

## 2. Core Components

### 2.1. Models (Domain & Data Layer)
Models represent the data structures and state of the application. They are pure Swift constructs without any dependency on UI frameworks.
- **Entities:** `TestCase`, `InferenceMetrics`, `LLMModelConfig` (represents a model's metadata, URL, and local path).
- **Persistence:** Models that need to be saved (like metrics or downloaded model lists) use **SwiftData** (e.g., `MetricsEntity`).

### 2.2. Views (UI Layer)
Views are declarative structures written in **SwiftUI**. They are responsible *only* for rendering the UI and forwarding user intents to the ViewModel.
- Views observe ViewModels using `@StateObject` or `@EnvironmentObject`.
- **Rule:** Views should contain **zero** business logic or direct calls to inference services.

### 2.3. ViewModels (Presentation Logic Layer)
ViewModels act as the bridge between Views and Services.
- They conform to `ObservableObject`.
- They expose `@Published` properties that Views observe to update their state.
- They handle user actions (e.g., "Run Inference", "Download Model") by calling the appropriate Services.
- **Scalability:** ViewModels are agnostic to *which* model is running. They rely on the injected configuration or state to pass the correct parameters to the services.

### 2.4. Services (Business Logic & External Systems)
Services handle the heavy lifting, such as file management, network requests, and AI inference. 
To prepare for **Gemma 4 E2B** and future models, Services should be designed using **Protocol-Oriented Programming**.

- `LLMInferenceServiceProtocol`: Defines methods like `generateResponse(prompt: String) async throws -> String`.
- `MediaPipeInferenceService`: A concrete implementation of the protocol that uses MediaPipe Tasks GenAI. It is initialized with a specific local model path, allowing the same service class to run Gemma 2B or Gemma 4 E2B depending on the user's selection.
- `ModelFileService`: Handles downloading `.bin` files from URLs, tracking download progress, and deleting local files.

## 3. Scalability for Gemma 4 E2B & Multi-Model Support

To support the Gemma 4 E2B model alongside the existing Gemma 2B model, the architecture adheres to the following principles:

1. **Dynamic Initialization:** The `LLMInferenceService` is no longer a static singleton tied to a hardcoded `Config.swift`. Instead, it is initialized dynamically based on the currently selected model's local file path.
2. **Protocol Abstraction:** If Gemma 4 E2B requires a different framework or different prompt wrapping logic in the future, we can create a new service conforming to `LLMInferenceServiceProtocol` without changing the ViewModels or Views.
3. **State Management:** An `AppState` or `ModelManager` (Environment Object) holds the currently "Active Model". ViewModels react to changes in this state and re-initialize their inference sessions accordingly.

## 4. Data Flow Example (Inference)
1. **User** taps "Run" on `InferenceView`.
2. `InferenceView` calls `viewModel.runInference(text: input)`.
3. `InferenceViewModel` retrieves the currently active model path from `AppState`.
4. `InferenceViewModel` calls `inferenceService.generateResponse(prompt: formattedPrompt, modelPath: activePath)`.
5. `LLMInferenceService` executes the MediaPipe task.
6. The result is returned to the ViewModel, which updates its `@Published var resultText`.
7. `InferenceView` automatically re-renders to show the result.
