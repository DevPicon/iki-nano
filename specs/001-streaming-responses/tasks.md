# Tasks: Implement Streaming LLM Responses

## Phase 1: Setup
- [x] T001 [P] Create `jira-mapping.json` for SCRUM-5

## Phase 2: Foundational
- [x] T002 Update `LLMInferenceService.swift` to support streaming callbacks in `generateResponseStream`

## Phase 3: User Story 1 - Real-time Inference Feedback (Priority: P1) 🎯 MVP
- [x] T003 Implement `generateResponseStream` using MediaPipe streaming API
- [x] T004 Update `MainViewModel.swift` to handle partial response updates
- [x] T005 Update `InferenceView.swift` to display streaming text
- [x] T006 Update `InferenceMetrics.swift` to include Time-to-First-Token (TTFT)
