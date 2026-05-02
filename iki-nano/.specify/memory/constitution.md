<!--
Sync Impact Report:
- Version change: INITIAL -> 1.0.0 (Initial project-specific ratification)
- List of modified principles:
  - Added: I. On-Device AI First
  - Added: II. Scalable MVVM Architecture
  - Added: III. Metrics-Driven Development
  - Added: IV. Privacy & Configuration Security
  - Added: V. Prompt-Centric Quality
- Templates requiring updates:
  - .specify/templates/plan-template.md (✅ updated)
  - .specify/templates/spec-template.md (✅ checked)
  - .specify/templates/tasks-template.md (✅ checked)
- Follow-up TODOs: None
-->

# iki-nano Constitution

## Core Principles

### I. On-Device AI First
All AI inference MUST happen locally on the device using MediaPipe Tasks GenAI. No user data should be sent to external servers for processing. This ensures maximum privacy, offline capability, and zero latency related to network round-trips for inference.

### II. Scalable MVVM Architecture
Maintain a strict separation between Views, ViewModels, and Services.
- **Views:** Declarative SwiftUI, zero business logic.
- **ViewModels:** Bridge between UI and Services, state management using `@Published`.
- **Services:** Protocol-oriented business logic. Services must be injectable and agnostic of the specific model weights where possible.

### III. Metrics-Driven Development
Every inference operation must be accompanied by rigorous performance metrics collection. This includes tracking:
- **Inference Latency:** Time from request to full response.
- **Token Efficiency:** Input and output token counts (using word-based estimation where necessary).
- **Resource Usage:** Peak memory consumption during inference.
- **Initialization Time:** Cold start vs. warm start timings for model loading.

### IV. Privacy & Configuration Security
User privacy is paramount. Model inference and metrics stay local in the app sandbox (SwiftData). Sensitive configurations, such as specific model download URLs, must be excluded from version control using local `Config.swift` files based on provided templates.

### V. Prompt-Centric Quality
For iOS, where specialized ML Kit APIs may be unavailable, prompt engineering is a core development task. Prompts must follow the Gemma instruction format and be validated against the standard 20+ test cases across all capabilities (Summarization, Proofreading, and Rewriting).

## Technical Standards

### Technology Stack
- **Language:** Swift (Modern concurrency with async/await)
- **UI:** SwiftUI (Targeting iOS 17.0+)
- **ML Engine:** MediaPipe Tasks GenAI
- **Persistence:** SwiftData for metrics and application state
- **Dependencies:** CocoaPods for framework management

### Performance Targets
- **Inference Time:** < 5s for typical inputs (< 500 words).
- **Memory Footprint:** < 1GB peak during inference for 2B models.
- **Stability:** Zero crashes during model swap or intensive inference sessions.

## Development Workflow

### Feature Implementation
1. **Service Protocol:** Define or update the service protocol.
2. **Prompt Design:** Draft and validate prompts for the specific capability.
3. **ViewModel Integration:** Implement logic to handle state and metrics.
4. **UI Rendering:** Create or update SwiftUI components to display results and metrics.
5. **Verification:** Run standard test cases and verify metrics persistence.

### Governance
This Constitution supersedes general practices for the `iki-nano` project. Any architectural deviations must be documented in `docs/` and justified based on performance or model compatibility requirements.

**Version**: 1.0.0 | **Ratified**: 2026-05-02 | **Last Amended**: 2026-05-02

