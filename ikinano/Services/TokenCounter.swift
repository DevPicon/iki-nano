//
//  TokenCounter.swift
//  ikinano
//

import Foundation

class TokenCounter {
    static func estimateTokens(text: String) -> Int {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }

        let words = text.split(separator: " ").count
        let punctuation = text.filter { ".,!?;:\"'()[]{}…—–-".contains($0) }.count

        return Int(Double(words) * 1.3 + Double(punctuation) * 0.3)
    }
}
