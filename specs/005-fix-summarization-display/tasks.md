# Tasks: Fix Summarization Display Bug

## Phase 1: Research & Reproduction
- [x] T001 Verify `InferenceView.swift` logic for updating `outputText` during streaming vs final completion.
- [x] T002 Inspect `LLMInferenceService.swift` to ensure `onPartialResponse` is correctly called for summarization prompts.

## Phase 2: Implementation
- [x] T003 Fix state binding or update logic in `InferenceView.swift` to ensure summarization results are displayed.
- [x] T004 Add diagnostic logging if the issue persists to capture the exact model output for summarization.

## Phase 3: Validation
- [x] T005 Run summarization with 3 different test cases and verify UI display.
