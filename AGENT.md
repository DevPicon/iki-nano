# Agent Configuration & Project State: iki-nano

**Project:** `iki-nano` (iOS Submodule for On-Device AI Labs)
**Last Updated:** Phase 4 Complete - Application Ready for Testing
**Primary AI Model:** Gemma 2B (int4 quantized, ~2.6B parameters)

This document provides a summary of the current state of the `iki-nano` iOS application to inform autonomous agents of the project's structure, implementation details, and immediate next steps.

## 🎯 Executive Summary
`iki-nano` is a native iOS application built to run on-device language models using MediaPipe Tasks GenAI. It is part of a comparative benchmark system against an Android counterpart (`miyabi-nano`). The core foundation, UI, data models, and prompt engineering are fully implemented.

## 🛠 Tech Stack
- **Language:** Swift 5.x
- **Platform:** iOS 17.0+
- **Architecture:** MVVM + Services
- **UI Framework:** SwiftUI
- **Database:** SwiftData
- **AI Framework:** MediaPipe Tasks GenAI
- **Dependency Manager:** CocoaPods

## ✅ Implemented Features
1. **Capabilities (Prompt-Engineered):**
   - Summarization
   - Proofreading
   - Rewrite (Formal)
   - Rewrite (Casual)
   - Rewrite (Concise)
2. **Metrics Collection:**
   - Latency (ms)
   - Estimated Token Count (input/output approximation)
   - Memory Usage (MB)
   - Model Load Time
3. **Database & Persistence Layer:**
   - `MetricsEntity` (@Model macro)
   - `MetricsRepository` (SwiftData FetchDescriptor)
   - Configured `ModelContainer` in `ikinanoApp`
4. **UI Components:**
   - Main menu with 5 capability cards.
   - Modally presented `InferenceView`.
   - `TestDataSelector` sheet containing 20 hardcoded test cases.
   - Formatted `MetricsCard` component.

## 📝 High Priority Pending Tasks
These tasks represent the immediate next steps to finalize the core benchmarking functionality:

1. **Metrics Persistence Integration in UI**
   - **Status:** Infrastructure complete (`MetricsRepository`), but not integrated into the view flow.
   - **Action Needed:** Add `modelContext` injection to `InferenceView`. Call `repository.saveMetrics()` after successful inferences.

2. **Metrics History View**
   - **Status:** Not started.
   - **Action Needed:** Create `Views/MetricsListView.swift`. Implement list displaying all metrics sorted by timestamp, a "Delete all" button, and swipe-to-delete. Add navigation from the Main Menu.

3. **CSV Export UI Integration**
   - **Status:** Backend functionality exists in `MetricsViewModel.exportToCSV()`.
   - **Action Needed:** Add an "Export Data" button to `MainMenuView`. Present a native iOS share sheet to export the generated CSV string.

## 🏗 Medium Priority Tasks
- **Prompt Validation Testing:** Create an XCTest suite (`PromptValidatorTests.swift`) to run all 20 test cases through the existing `PromptValidator`.
- **Input Validation:** Implement logic in `InferenceView` to validate text length, minimum limits, and whitespace before passing input to the inference service.
- **Model Status Indicator:** Enhance UI to show download state, model file size, and availability status on the main menu.

## ⚠️ Known Limitations & Context
- **Gemma 2B Wrapper:** iOS requires wrapping prompts in the Gemma instruction format (`<start_of_turn>user
...
<start_of_turn>model`).
- **Token Counting:** Uses a word-based estimation (`words * 1.3 + punctuation * 0.3`). This is an approximation since standard framework tokenizers are unavailable.
- **Memory Tracking:** Captures relative change using `mach_task_basic_info`.
- **Hardware Profile:** Requires a device with Apple Silicon (A-series chips) and at least ~1.5 GB to 2 GB free space for the `.bin` model file.
- **No Cloud Services:** All inference runs 100% offline.

## 📁 Key File Locations
- **Dependency Loading:** `Podfile` & `ikinano.xcworkspace`
- **Core AI Service:** `Services/LLMInferenceService.swift`
- **Data Models:** `Models/InferenceMetrics.swift`, `Models/MetricsEntity.swift`
- **Architecture Guidelines:** `docs/architecture-mvvm.md`
- **Model Management Plan:** `docs/project-plan-model-management.md`
- **UI Entry Point:** `Views/MainMenuView.swift`
- **Test Data:** `Repositories/TestDataRepository.swift`
