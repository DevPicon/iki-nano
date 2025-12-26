# Prompt Engineering Documentation

## Overview

This document details the prompt templates used in the iki-nano iOS application to replicate ML Kit GenAI API behaviors using the Gemma 2B model with custom prompts.

## Prompt Format

All prompts follow the Gemma instruction format:

```
<start_of_turn>user
{instruction and input text}
<end_of_turn>
<start_of_turn>model
```

This format signals to the Gemma model that:
1. The user is providing an instruction
2. The model should generate a response after `<start_of_turn>model`

## Capability Prompts

### 1. Summarization

**Purpose:** Condense long text into concise key points while preserving essential information.

**Matches:** ML Kit Summarization API with `InputType.ARTICLE` and `OutputType.ONE_BULLET`

**Template:**
```
Summarize the following text in a concise and clear way.
Keep the key ideas, remove redundancies, and avoid adding new information.
Return the summary in one short paragraph.
Do not include any introductory phrases. Return ONLY the summary text.
Text:
"""
{input_text}
"""
```

**Key Instructions:**
- "concise and clear" → ensures brevity
- "Keep the key ideas" → preserves important information
- "remove redundancies" → eliminates repetition
- "avoid adding new information" → prevents hallucination
- "Return ONLY the summary text" → prevents meta-commentary

**Expected Behavior:**
- Input: 200-1000 word article
- Output: 1-3 sentence summary capturing main points

---

### 2. Proofreading

**Purpose:** Fix grammar, spelling, punctuation, and syntax errors while preserving original meaning.

**Matches:** ML Kit Proofreading API with `InputType.KEYBOARD` and `Language.ENGLISH`

**Template:**
```
Proofread the following text. Fix grammar, spelling, punctuation, and syntax errors.
Preserve the original meaning and style.
Return ONLY the corrected text without explanations.

Text:
"""
{input_text}
"""
```

**Key Instructions:**
- "Fix grammar, spelling, punctuation, and syntax errors" → comprehensive error correction
- "Preserve the original meaning and style" → maintains user intent and voice
- "Return ONLY the corrected text" → no explanations or annotations

**Expected Behavior:**
- Input: Text with grammatical/spelling errors
- Output: Same text with errors corrected, structure preserved

**Example:**
- Input: "I goes to the store yesterday and buy some apple."
- Output: "I went to the store yesterday and bought some apples."

---

### 3. Rewrite - Formal

**Purpose:** Transform casual text into professional, formal language.

**Matches:** ML Kit Rewriting API with `OutputType.PROFESSIONAL` and `Language.ENGLISH`

**Template:**
```
Rewrite the following text in a formal, professional tone.
Preserve the original meaning, improve clarity and grammar,
and remove casual expressions or slang.
Return only the rewritten text.
Do not include any introductory phrases. Return ONLY the rewritten text.
Text:
"""
{input_text}
"""
```

**Key Instructions:**
- "formal, professional tone" → business-appropriate language
- "Preserve the original meaning" → keeps core message intact
- "improve clarity and grammar" → enhances readability
- "remove casual expressions or slang" → eliminates informal language

**Expected Behavior:**
- Input: Casual message (e.g., "Hey, can't make it tomorrow. Something came up!")
- Output: Formal version (e.g., "I regret to inform you that I will be unable to attend tomorrow due to an unforeseen commitment.")

---

### 4. Rewrite - Casual

**Purpose:** Transform formal text into friendly, conversational language.

**Matches:** ML Kit Rewriting API with `OutputType.FRIENDLY` and `Language.ENGLISH`

**Template:**
```
Rewrite the following text in a casual, friendly tone.
Preserve the original meaning, use conversational language,
and make it more approachable.
Return only the rewritten text.
Do not include any introductory phrases. Return ONLY the rewritten text.
Text:
"""
{input_text}
"""
```

**Key Instructions:**
- "casual, friendly tone" → conversational style
- "use conversational language" → natural speech patterns
- "make it more approachable" → warm and inviting

**Expected Behavior:**
- Input: Formal text (e.g., "I am writing to inform you that I will be unable to attend.")
- Output: Casual version (e.g., "Hey! Just wanted to let you know I can't make it.")

---

### 5. Rewrite - Concise

**Purpose:** Remove unnecessary words while preserving all key information.

**Matches:** ML Kit Rewriting API with `OutputType.SHORTEN` and `Language.ENGLISH`

**Template:**
```
Rewrite the following text to be more concise and direct.
Remove unnecessary words while preserving all key information.
Return only the rewritten text.
Do not include any introductory phrases. Return ONLY the rewritten text.
Text:
"""
{input_text}
"""
```

**Key Instructions:**
- "more concise and direct" → eliminates verbosity
- "Remove unnecessary words" → cuts filler
- "preserving all key information" → keeps essential content

**Expected Behavior:**
- Input: Verbose text (e.g., "I wanted to take a moment to reach out and let you know that I've been giving some thought to your proposal, and after careful consideration, I believe we should move forward.")
- Output: Concise version (e.g., "After considering your proposal, I believe we should proceed.")

---

## Prompt Design Principles

### 1. Explicit Output Format
All prompts include "Return ONLY the [output type]" to prevent the model from adding:
- Introductory phrases ("Here is the summary:")
- Explanatory text ("I've corrected the following errors:")
- Meta-commentary

### 2. Preservation Instructions
Each prompt explicitly states what to preserve:
- Summarization: key ideas
- Proofreading: original meaning and style
- Rewriting: original meaning

### 3. Constraint Specification
Prompts clearly define what NOT to do:
- Don't add new information
- Don't include explanations
- Don't change meaning

### 4. Triple-Quote Delimiter
Input text is wrapped in `"""` to:
- Clearly separate instructions from content
- Handle multiline input correctly
- Prevent injection attacks

### 5. Gemma Instruction Format
All prompts are wrapped in Gemma-specific tokens:
```
<start_of_turn>user
{prompt}
<end_of_turn>
<start_of_turn>model
```

This format is critical for Gemma 2B to understand the task structure.

---

## Implementation Location

**File:** `ikinano/ViewModels/MainViewModel.swift`

**Enum:** `InferenceTask` (lines 161-244)

**Method:** `buildPrompt(with text: String) -> String` (lines 168-228)

**Formatting:** `runTaskInference(task:text:)` applies Gemma instruction tokens (lines 146-157)

---

## Testing Recommendations

### 1. Output Format Validation
Verify that model outputs:
- Contain ONLY the requested content
- Do NOT include introductory phrases
- Do NOT include explanations

### 2. Capability-Specific Testing

**Summarization:**
- Test with short (200 words), medium (500 words), and long (1000+ words) articles
- Verify key information is preserved
- Check that no new information is added

**Proofreading:**
- Test with various error types (grammar, spelling, punctuation)
- Verify original meaning is preserved
- Check that style/tone remains consistent

**Rewrite Formal:**
- Test with casual messages, informal emails
- Verify tone shifts to professional
- Check that meaning is preserved

**Rewrite Casual:**
- Test with formal announcements, professional emails
- Verify tone shifts to friendly
- Check that meaning is preserved

**Rewrite Concise:**
- Test with verbose, wordy text
- Verify all key information is retained
- Check that length is reduced significantly

### 3. Edge Cases
- Empty input
- Very short input (< 10 words)
- Very long input (> 1000 words)
- Input with special characters
- Input with code blocks or formatting

---

## Comparison with ML Kit APIs

| Capability | iOS (Gemma 2B) | Android (ML Kit) |
|------------|----------------|------------------|
| Summarization | Custom prompt | Summarization API with `ONE_BULLET` |
| Proofreading | Custom prompt | Proofreading API with `KEYBOARD` |
| Rewrite Formal | Custom prompt | Rewriting API with `PROFESSIONAL` |
| Rewrite Casual | Custom prompt | Rewriting API with `FRIENDLY` |
| Rewrite Concise | Custom prompt | Rewriting API with `SHORTEN` |

**Key Difference:** Android uses dedicated ML Kit APIs optimized for each task, while iOS uses general-purpose Gemma 2B model with carefully crafted prompts.

**Benchmark Goal:** Compare output quality and performance between dedicated APIs and prompt-based approaches.

---

## Prompt Tuning History

### Version 1.0 (Current)
- Initial prompt templates created
- Gemma instruction format applied
- Triple-quote delimiters for input text
- Explicit "Return ONLY" instructions to prevent meta-commentary

### Future Improvements
- Add few-shot examples for better consistency
- Experiment with temperature/top-k parameters
- Test alternative phrasings for edge cases
- Add length constraints for summarization

---

## References

- [Gemma 2B Model Card](https://huggingface.co/google/gemma-2b-it)
- [ML Kit Summarization API](https://developers.google.com/ml-kit/genai/summarization/android)
- [ML Kit Proofreading API](https://developers.google.com/ml-kit/genai/proofreading/android)
- [ML Kit Rewriting API](https://developers.google.com/ml-kit/genai/rewriting/android)
