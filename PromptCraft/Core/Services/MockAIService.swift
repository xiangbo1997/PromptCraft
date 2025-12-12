import Foundation

/// A mock implementation of `AIServiceProtocol` for testing and development.
/// This service simulates AI responses without making actual network calls.
class MockAIService: AIServiceProtocol {
    
    /// Simulates optimizing a prompt by returning a predefined, detailed string after a delay.
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1.5))
        
        // Return a detailed, hardcoded response based on the mode
        switch mode {
        case .concise:
            return "This is a concise and optimized version of your prompt: '\(prompt)'."
        case .detailed:
            return """
            **Role:** You are a world-class AI assistant.
            **Task:** Elaborate on the user's prompt.
            **Context:** The user provided the following input: "\(prompt)".
            **Action:** Generate a detailed, structured, and comprehensive response that fully addresses the user's request, providing examples and clear explanations.
            """
        case .professional:
            return """
            ### OBJECTIVE
            To professionally expand and structure the user's request for a formal or technical audience.

            ### USER INPUT
            "\(prompt)"

            ### REFINED PROMPT
            Please provide a professional-grade analysis and response to the user's input. The output should be formatted in Markdown, including sections for background, key points, and a concluding summary. The tone should be formal and authoritative.
            """
        }
    }
    
    /// Simulates a streaming optimization, yielding chunks of a predefined string over time.
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error> {
        let response = "This is a simulated stream for the prompt: '\(prompt)'. It demonstrates how text can be delivered in chunks, providing a more responsive user experience."
        
        return AsyncThrowingStream { continuation in
            Task {
                for word in response.split(separator: " ") {
                    continuation.yield(String(word) + " ")
                    try await Task.sleep(for: .milliseconds(50)) // Simulate streaming chunks
                }
                continuation.finish()
            }
        }
    }
    
    /// Simulates validating an API key. Always returns `true` for mock purposes.
    func validateAPIKey(_ key: String) async throws -> Bool {
        try await Task.sleep(for: .seconds(0.5))
        return true
    }
    
    /// Simulates fetching available AI models.
    func fetchModels() async throws -> [AIModel] {
        try await Task.sleep(for: .seconds(0.5))
        return [
            .gpt4Turbo,
            .gpt4,
            .gpt35Turbo,
            .claude3Opus,
            .claude3Sonnet
        ]
    }

    /// 模拟生成标题
    func generateTitle(for content: String) async throws -> String {
        try await Task.sleep(for: .seconds(0.3))
        // 从内容中提取前几个词作为模拟标题
        let words = content.split(separator: " ").prefix(4)
        return words.joined(separator: " ") + "..."
    }
}
