//
//  TestDataRepository.swift
//  ikinano
//

import Foundation

class TestDataRepository {

    static let summarizationTests: [TestCase] = [
        TestCase(
            id: "sum_tech_1",
            name: "Technical Article",
            capability: .summarization,
            inputText: """
                Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed. It focuses on the development of computer programs that can access data and use it to learn for themselves. The process of learning begins with observations or data, such as examples, direct experience, or instruction, in order to look for patterns in data and make better decisions in the future based on the examples that we provide. The primary aim is to allow the computers to learn automatically without human intervention or assistance and adjust actions accordingly.
                """,
            expectedOutputGuidelines: nil,
            category: .technical
        ),
        TestCase(
            id: "sum_business_1",
            name: "Business News",
            capability: .summarization,
            inputText: """
                The company reported strong quarterly earnings, exceeding analyst expectations by 15 percent. Revenue growth was driven primarily by increased demand in the cloud services division, which saw a 28 percent year-over-year increase. The CEO attributed the success to strategic investments in infrastructure and talent acquisition over the past two years. However, the company faces increasing competition from emerging startups and established tech giants entering the market. Looking ahead, management expressed confidence in maintaining growth momentum through continued innovation and customer-focused product development.
                """,
            expectedOutputGuidelines: nil,
            category: .mediumText
        ),
        TestCase(
            id: "sum_casual_1",
            name: "Blog Post",
            capability: .summarization,
            inputText: """
                I recently tried the new Italian restaurant downtown and I have to say, I was thoroughly impressed! The ambiance was cozy and welcoming, with soft lighting and beautiful decor. We started with the bruschetta which was absolutely delicious - fresh tomatoes, perfectly toasted bread, and just the right amount of garlic. For the main course, I ordered the carbonara and my partner got the lasagna. Both dishes were outstanding. The pasta was cooked al dente and the sauces were rich and flavorful. The service was attentive without being intrusive. Overall, it's definitely worth a visit if you're in the area!
                """,
            expectedOutputGuidelines: nil,
            category: .casual
        ),
        TestCase(
            id: "sum_short_1",
            name: "Short News",
            capability: .summarization,
            inputText: """
                Local authorities announced new traffic regulations that will take effect next month. The changes include reduced speed limits in school zones and increased fines for violations. Residents have expressed mixed reactions to the announcement.
                """,
            expectedOutputGuidelines: nil,
            category: .shortText
        ),
        TestCase(
            id: "sum_long_1",
            name: "Research Summary",
            capability: .summarization,
            inputText: """
                Recent studies in cognitive neuroscience have revealed fascinating insights into how the human brain processes and retains information. Researchers at several leading universities have been investigating the neural mechanisms underlying memory formation and retrieval. Their findings suggest that the hippocampus plays a more complex role than previously understood. Using advanced imaging techniques, scientists have observed that different types of memories activate distinct neural pathways. Episodic memories, which involve personal experiences, show increased activity in the medial temporal lobe, while semantic memories, related to facts and concepts, engage broader cortical networks. The research also indicates that sleep plays a crucial role in memory consolidation, with specific sleep stages corresponding to different types of memory processing. These discoveries could have significant implications for developing treatments for memory-related disorders and improving educational methodologies. The interdisciplinary team plans to continue their investigation, focusing on how external factors such as stress and nutrition affect cognitive function.
                """,
            expectedOutputGuidelines: nil,
            category: .longText
        )
    ]

    static let proofreadingTests: [TestCase] = [
        TestCase(
            id: "proof_grammar_1",
            name: "Grammar Errors",
            capability: .proofreading,
            inputText: "I goes to the store yesterday and buy some apple. Their very delicious!",
            expectedOutputGuidelines: nil,
            category: .errorRich
        ),
        TestCase(
            id: "proof_spelling_1",
            name: "Spelling Mistakes",
            capability: .proofreading,
            inputText: "The managment team has recieved several complains about the new polocies. We need to adress these isues immediatly.",
            expectedOutputGuidelines: nil,
            category: .errorRich
        ),
        TestCase(
            id: "proof_punctuation_1",
            name: "Punctuation Issues",
            capability: .proofreading,
            inputText: "hello how are you doing today i hope youre having a great day lets meet tomorrow at 3pm okay",
            expectedOutputGuidelines: nil,
            category: .errorRich
        ),
        TestCase(
            id: "proof_mixed_1",
            name: "Mixed Errors",
            capability: .proofreading,
            inputText: "The studens was working on there project when the teacher come in. She told them too finish it by tommorow.",
            expectedOutputGuidelines: nil,
            category: .errorRich
        ),
        TestCase(
            id: "proof_casual_1",
            name: "Casual Message",
            capability: .proofreading,
            inputText: "hey do u wanna grab lunch 2day? im thinking bout that new place on main st. lmk!",
            expectedOutputGuidelines: nil,
            category: .casual
        )
    ]

    static let rewriteFormalTests: [TestCase] = [
        TestCase(
            id: "rewrite_formal_1",
            name: "Casual to Professional",
            capability: .rewriteFormal,
            inputText: "Hey, I wanted to let you know that I can't make it to the meeting tomorrow. Something came up and I gotta deal with it. Sorry about that!",
            expectedOutputGuidelines: nil,
            category: .casual
        ),
        TestCase(
            id: "rewrite_formal_2",
            name: "Email Response",
            capability: .rewriteFormal,
            inputText: "Yeah, I got your message about the project deadline. No worries, I'll get it done by Friday. Thanks for the heads up!",
            expectedOutputGuidelines: nil,
            category: .casual
        ),
        TestCase(
            id: "rewrite_formal_3",
            name: "Business Communication",
            capability: .rewriteFormal,
            inputText: "So basically what we're trying to do here is make the app run faster. We think if we optimize the database stuff, things will work better.",
            expectedOutputGuidelines: nil,
            category: .technical
        ),
        TestCase(
            id: "rewrite_formal_4",
            name: "Customer Service",
            capability: .rewriteFormal,
            inputText: "Sorry about the delay! We had some issues on our end but we're working on fixing them. Your order should ship out soon.",
            expectedOutputGuidelines: nil,
            category: .casual
        )
    ]

    static let rewriteCasualTests: [TestCase] = [
        TestCase(
            id: "rewrite_casual_1",
            name: "Formal to Friendly",
            capability: .rewriteCasual,
            inputText: "I am writing to inform you that I will be unable to attend the scheduled meeting tomorrow due to a prior commitment. I apologize for any inconvenience this may cause.",
            expectedOutputGuidelines: nil,
            category: .formal
        ),
        TestCase(
            id: "rewrite_casual_2",
            name: "Professional Email",
            capability: .rewriteCasual,
            inputText: "Thank you for your inquiry regarding our services. We would be pleased to schedule a consultation at your earliest convenience to discuss your requirements in detail.",
            expectedOutputGuidelines: nil,
            category: .formal
        ),
        TestCase(
            id: "rewrite_casual_3",
            name: "Technical Documentation",
            capability: .rewriteCasual,
            inputText: "The system has been configured to automatically generate reports on a weekly basis. Users may access these documents through the administrative dashboard.",
            expectedOutputGuidelines: nil,
            category: .technical
        ),
        TestCase(
            id: "rewrite_casual_4",
            name: "Announcement",
            capability: .rewriteCasual,
            inputText: "Please be advised that the facility will be closed for maintenance on Saturday. We appreciate your understanding and cooperation in this matter.",
            expectedOutputGuidelines: nil,
            category: .formal
        )
    ]

    static let rewriteConciseTests: [TestCase] = [
        TestCase(
            id: "rewrite_concise_1",
            name: "Verbose Email",
            capability: .rewriteConcise,
            inputText: "I wanted to take a moment to reach out and let you know that I've been giving some thought to your proposal, and after careful consideration and discussion with my team, I believe we should move forward with the project.",
            expectedOutputGuidelines: nil,
            category: .formal
        ),
        TestCase(
            id: "rewrite_concise_2",
            name: "Long Explanation",
            capability: .rewriteConcise,
            inputText: "In order to complete the registration process, you will need to fill out all of the required fields in the form, including your name, email address, and phone number, and then click on the submit button at the bottom of the page.",
            expectedOutputGuidelines: nil,
            category: .technical
        ),
        TestCase(
            id: "rewrite_concise_3",
            name: "Wordy Instructions",
            capability: .rewriteConcise,
            inputText: "If you happen to experience any kind of issues or problems while you are using the application, please don't hesitate to contact our support team who will be more than happy to assist you.",
            expectedOutputGuidelines: nil,
            category: .formal
        ),
        TestCase(
            id: "rewrite_concise_4",
            name: "Redundant Message",
            capability: .rewriteConcise,
            inputText: "At this point in time, we are currently in the process of reviewing and evaluating all of the different options and alternatives that are available to us.",
            expectedOutputGuidelines: nil,
            category: .general
        )
    ]

    static func getTestCases(for capability: InferenceCapability) -> [TestCase] {
        switch capability {
        case .summarization:
            return summarizationTests
        case .proofreading:
            return proofreadingTests
        case .rewriteFormal:
            return rewriteFormalTests
        case .rewriteCasual:
            return rewriteCasualTests
        case .rewriteConcise:
            return rewriteConciseTests
        }
    }

    static func getAllTestCases() -> [TestCase] {
        return summarizationTests + proofreadingTests + rewriteFormalTests + rewriteCasualTests + rewriteConciseTests
    }
}
