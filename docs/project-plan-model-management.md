# Project Plan: Dynamic Model Management

**Project:** `iki-nano` (iOS)
**Objective:** Implement a robust system to manage multiple LLM models (e.g., Gemma 2B, Gemma 4 E2B). Users should be able to load a list of model URLs from a file, add custom URLs, track download states, delete models locally, and select an active model to be used across the application.

## 1. Requirements

### 1.1. Model Registry & Input
- Read a default list of model URLs from an embedded file (e.g., `models.json`).
- Provide a UI for users to manually input and add custom model URLs.
- Store the complete list of known models persistently (using SwiftData or UserDefaults).

### 1.2. Download State Management
- Track the state of each model: `Not Downloaded`, `Downloading` (with progress), `Downloaded`.
- Verify the existence of the local `.bin` file to ensure the state remains accurate across app launches.

### 1.3. Local File Management (Deletion)
- Allow users to delete a downloaded model to free up device storage.
- Deleting a model should:
  1. Remove the local `.bin` file from the device's Documents directory.
  2. Update the model's state back to `Not Downloaded`.
  3. Optionally, allow removing the model entry entirely from the registry if it was custom-added.

### 1.4. Active Model Selection
- Provide a UI component on the `MainMenuView` (e.g., a Picker or a specialized card) to select the "Active Model" from the list of downloaded models.
- The selected active model must be globally accessible (via `AppState` or injected configuration).
- All inference operations on subsequent screens (`InferenceView`) must automatically use the currently selected active model.

## 2. Implementation Phases

### Phase 1: Data Modeling and Persistence
**Goal:** Define the data structures to hold model information and persist them.
- Create a `LLMModel` struct/class containing:
  - `id`: UUID
  - `name`: String (e.g., "Gemma 4 E2B")
  - `url`: URL
  - `localFilename`: String
  - `isDownloaded`: Bool (computed based on file existence)
- Setup a repository (`ModelRepository`) to load initial models from a JSON file and persist user-added models.

### Phase 2: File Service Enhancements
**Goal:** Upgrade `ModelFileService` to handle multiple concurrent models.
- Refactor download logic to accept a specific URL and destination filename rather than relying on a hardcoded config.
- Implement a `deleteModel(filename:)` function using `FileManager`.
- Ensure download progress can be tracked independently per model.

### Phase 3: UI - Model Management Screen
**Goal:** Create a dedicated screen for managing models.
- Build `ModelManagementView` containing a List of all known models.
- Each row should display: Model Name, Download Button (or Progress Bar), and a Delete (Trash) button if downloaded.
- Add a "+" button to present a sheet for adding a custom Model URL and Name.

### Phase 4: UI - Active Model Selection
**Goal:** Allow users to choose which model to use.
- Update `MainMenuView` to include a "Current Model" selector.
- This selector should only allow choosing from models that have `isDownloaded == true`.
- Store the selected model's ID in `AppStorage` or an `EnvironmentObject` (`AppState`).

### Phase 5: Inference Service Integration
**Goal:** Tie the active model to the inference engine.
- Update `LLMInferenceService` to initialize the MediaPipe Task using the local path of the *Active Model*.
- Handle edge cases: e.g., if the user deletes the currently active model, fallback to another downloaded model or prompt the user to download one.
- Ensure the `InferenceViewModel` fetches the correct model context before starting generation.

## 3. Scope and Timeline Estimate
- **Phase 1 & 2 (Data & Services):** Core backend work. Needs careful file management logic.
- **Phase 3 (Management UI):** SwiftUI views for downloading and deleting.
- **Phase 4 & 5 (Selection & Inference):** Wiring the selected state into the existing MVVM flow.

*Note: This architecture directly supports the imminent testing of Gemma 4 E2B by allowing the user to simply paste the HuggingFace URL of the new model, download it, select it, and immediately run the benchmark tests against it.*
