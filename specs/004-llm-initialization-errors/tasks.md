# Tasks: Enhance LLM Initialization and Error Handling

## Phase 1: Setup
- [ ] T001 [P] Create `jira-mapping.json` for SCRUM-8

## Phase 2: Foundational
- [ ] T002 Define `LLMError` enum in `Models/`
- [ ] T003 Update `InferenceMetrics` to include `loadTime`

## Phase 3: User Story 1 - Robust Model Loading (Priority: P1) 🎯 MVP
- [ ] T004 Implement load time measurement in `LLMInferenceService.initialize()`
- [ ] T005 Implement granular error catching in `initialize()`
- [ ] T006 Update `AppState` to handle error display
- [ ] T007 Add initialization timeout logic in `MainViewModel`
