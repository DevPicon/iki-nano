//
//  TestCase.swift
//  ikinano
//

import Foundation

struct TestCase: Identifiable, Codable {
    let id: String
    let name: String
    let capability: InferenceCapability
    let inputText: String
    let expectedOutputGuidelines: String?
    let category: TestCategory
}

enum TestCategory: String, Codable {
    case shortText
    case mediumText
    case longText
    case technical
    case casual
    case formal
    case errorRich
    case general
}
