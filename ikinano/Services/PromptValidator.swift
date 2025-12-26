//
//  PromptValidator.swift
//  ikinano
//

import Foundation

/// Utility for validating prompt outputs meet expected criteria
struct PromptValidator {

    /// Validation result for a prompt output
    struct ValidationResult {
        let isValid: Bool
        let issues: [String]

        var description: String {
            if isValid {
                return "✅ Validation passed"
            } else {
                return "❌ Validation failed:\n" + issues.map { "  - \($0)" }.joined(separator: "\n")
            }
        }
    }

    /// Validate that output meets general quality criteria
    /// - Parameters:
    ///   - output: The generated text from the model
    ///   - capability: The inference capability used
    /// - Returns: ValidationResult with issues if any
    static func validate(output: String, capability: InferenceCapability) -> ValidationResult {
        var issues: [String] = []

        // Common validations for all capabilities
        issues.append(contentsOf: validateCommon(output: output))

        // Capability-specific validations
        switch capability {
        case .summarization:
            issues.append(contentsOf: validateSummarization(output: output))
        case .proofreading:
            issues.append(contentsOf: validateProofreading(output: output))
        case .rewriteFormal, .rewriteCasual, .rewriteConcise:
            issues.append(contentsOf: validateRewrite(output: output))
        }

        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }

    // MARK: - Common Validations

    private static func validateCommon(output: String) -> [String] {
        var issues: [String] = []

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for empty output
        if trimmed.isEmpty {
            issues.append("Output is empty")
            return issues
        }

        // Check for meta-commentary (model talking about what it's doing)
        let metaPhrases = [
            "here is",
            "here's",
            "i have",
            "i've",
            "the following",
            "below is",
            "as requested",
            "certainly",
            "of course"
        ]

        let lowerOutput = trimmed.lowercased()
        for phrase in metaPhrases {
            if lowerOutput.hasPrefix(phrase) {
                issues.append("Output contains meta-commentary prefix: '\(phrase)'")
                break
            }
        }

        // Check for explanation markers
        let explanationMarkers = [
            "explanation:",
            "note:",
            "changes made:",
            "corrections:",
            "i changed",
            "i corrected",
            "i rewrote"
        ]

        for marker in explanationMarkers {
            if lowerOutput.contains(marker) {
                issues.append("Output contains explanation marker: '\(marker)'")
                break
            }
        }

        return issues
    }

    // MARK: - Capability-Specific Validations

    private static func validateSummarization(output: String) -> [String] {
        var issues: [String] = []

        let sentences = output.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        // Summarization should be concise (typically 1-5 sentences)
        if sentences.count > 10 {
            issues.append("Summary is too long (\(sentences.count) sentences). Expected 1-5 sentences.")
        }

        // Check for summary markers
        if output.lowercased().contains("summary:") {
            issues.append("Output contains 'summary:' label - should only contain summary text")
        }

        return issues
    }

    private static func validateProofreading(output: String) -> [String] {
        var issues: [String] = []

        // Proofreading output should not contain explanations
        if output.contains("corrected") || output.contains("fixed") {
            issues.append("Output appears to contain explanations about corrections")
        }

        return issues
    }

    private static func validateRewrite(output: String) -> [String] {
        var issues: [String] = []

        // Rewrite output should not contain version labels
        if output.lowercased().contains("rewritten version") ||
           output.lowercased().contains("formal version") ||
           output.lowercased().contains("casual version") {
            issues.append("Output contains version labels - should only contain rewritten text")
        }

        return issues
    }

    // MARK: - Test Case Validation

    /// Validate output against a test case
    /// - Parameters:
    ///   - output: The generated text
    ///   - testCase: The test case with expected guidelines
    /// - Returns: ValidationResult
    static func validateTestCase(output: String, testCase: TestCase) -> ValidationResult {
        var issues: [String] = []

        // Basic validation
        let basicValidation = validate(output: output, capability: testCase.capability)
        issues.append(contentsOf: basicValidation.issues)

        // If test case has expected output guidelines, check them
        if let guidelines = testCase.expectedOutputGuidelines {
            // This is where you could add more specific validations
            // based on the guidelines if needed
            _ = guidelines // Placeholder for future use
        }

        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }

    // MARK: - Batch Validation

    /// Validate multiple outputs
    /// - Parameter outputs: Array of (output, capability) tuples
    /// - Returns: Dictionary of output index to validation result
    static func validateBatch(_ outputs: [(output: String, capability: InferenceCapability)]) -> [Int: ValidationResult] {
        var results: [Int: ValidationResult] = [:]

        for (index, item) in outputs.enumerated() {
            results[index] = validate(output: item.output, capability: item.capability)
        }

        return results
    }

    /// Generate validation summary for batch results
    /// - Parameter results: Dictionary of validation results
    /// - Returns: Summary string
    static func generateSummary(for results: [Int: ValidationResult]) -> String {
        let total = results.count
        let passed = results.values.filter { $0.isValid }.count
        let failed = total - passed
        let passRate = total > 0 ? Double(passed) / Double(total) * 100 : 0

        var summary = """

        📊 Validation Summary
        ═══════════════════
        Total:  \(total)
        Passed: \(passed) ✅
        Failed: \(failed) ❌
        Pass Rate: \(String(format: "%.1f", passRate))%

        """

        // Add details for failed cases
        if failed > 0 {
            summary += "\nFailed Cases:\n"
            for (index, result) in results.sorted(by: { $0.key < $1.key }) {
                if !result.isValid {
                    summary += "\nCase #\(index):\n"
                    summary += result.issues.map { "  - \($0)" }.joined(separator: "\n")
                    summary += "\n"
                }
            }
        }

        return summary
    }
}
