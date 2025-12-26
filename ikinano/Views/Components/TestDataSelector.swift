//
//  TestDataSelector.swift
//  ikinano
//

import SwiftUI

struct TestDataSelector: View {
    let testCases: [TestCase]
    let onTestCaseSelected: (TestCase) -> Void
    @Environment(\.dismiss) var dismiss

    var body: View {
        NavigationView {
            List(testCases) { testCase in
                Button(action: {
                    onTestCaseSelected(testCase)
                    dismiss()
                }) {
                    TestCaseRow(testCase: testCase)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Test Case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TestCaseRow: View {
    let testCase: TestCase

    var body: View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(testCase.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(testCase.category.rawValue.replacingOccurrences(of: "_", with: " ").lowercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }

            Text(testCase.inputText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TestDataSelector(
        testCases: [
            TestCase(
                id: "test1",
                name: "Technical Article",
                capability: .summarization,
                inputText: "Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed.",
                expectedOutputGuidelines: nil,
                category: .technical
            ),
            TestCase(
                id: "test2",
                name: "Business News",
                capability: .summarization,
                inputText: "The company reported strong quarterly earnings, exceeding analyst expectations by 15 percent.",
                expectedOutputGuidelines: nil,
                category: .mediumText
            )
        ],
        onTestCaseSelected: { _ in }
    )
}
