import Foundation
import Combine

// AI 错误类型
enum AIError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case emptyResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case timeout
    case rateLimitExceeded
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key 无效"
        case .invalidResponse:
            return "服务器响应无效"
        case .emptyResponse:
            return "服务器返回空内容"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .timeout:
            return "请求超时"
        case .rateLimitExceeded:
            return "API 调用次数超限或余额不足 (429)"
        case .unauthorized:
            return "API Key 错误或未授权 (401)"
        }
    }
}

// AI 模型枚举
// AI 模型结构体 (改为结构体以支持动态模型)
struct AIModel: Codable, Hashable, Identifiable {
    let id: String
    let name: String? // Optional display name
    
    init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
    
    // 预设模型
    static let gpt35Turbo = AIModel(id: "gpt-3.5-turbo")
    static let gpt4 = AIModel(id: "gpt-4")
    static let gpt4Turbo = AIModel(id: "gpt-4-turbo-preview")
    static let claude3Opus = AIModel(id: "claude-3-opus-20240229")
    static let claude3Sonnet = AIModel(id: "claude-3-sonnet-20240229")
    static let claude3Haiku = AIModel(id: "claude-3-haiku-20240307")
}

// AI 服务协议
protocol AIServiceProtocol {
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
    func fetchModels() async throws -> [AIModel]
    func generateTitle(for content: String) async throws -> String
}

// OpenAI 服务实现
class OpenAIService: AIServiceProtocol {
    private let baseURL: String
    private let apiKey: String
    private let model: AIModel
    private let timeout: TimeInterval
    private let session: URLSession
    
    init(
        apiKey: String,
        model: AIModel = .gpt4,
        baseURL: String = "https://api.openai.com/v1",
        timeout: TimeInterval = 30
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.timeout = timeout
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        self.session = URLSession(configuration: config)
    }
    
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
        let request = createRequest(prompt: prompt, mode: mode, stream: false)
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 [AIService] Received Response: \(httpResponse.statusCode)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response Body: \(dataString)")
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw AIError.emptyResponse
        }
        
        return content
    }
    
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let request = createRequest(prompt: prompt, mode: mode, stream: true)
                
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📥 [AIService] Stream Response Started: \(httpResponse.statusCode)")
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📥 [AIService] Stream Response Started: \(httpResponse.statusCode)")
                        
                        switch httpResponse.statusCode {
                        case 200:
                            break // Continue
                        case 401:
                            throw AIError.unauthorized
                        case 429:
                            throw AIError.rateLimitExceeded
                        default:
                            throw AIError.httpError(statusCode: httpResponse.statusCode)
                        }
                    }
                    
                    for try await line in bytes.lines {
                        // print("📝 [AIService] Stream Line: \(line)") // Optional: Uncomment if too verbose
                        
                        if line.hasPrefix("data: ") {
                            let data = line.dropFirst(6)
                            if data == "[DONE]" {
                                print("✅ [AIService] Stream DONE")
                                continuation.finish()
                                return
                            }
                            
                            if let jsonData = data.data(using: .utf8) {
                                do {
                                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                                    if let content = chunk.choices.first?.delta.content {
                                        // print("🔹 [AIService] Yielding content: \(content)")
                                        continuation.yield(content)
                                    }
                                } catch {
                                    print("⚠️ [AIService] JSON Decode Error: \(error)")
                                    print("⚠️ [AIService] Failed JSON: \(data)")
                                }
                            }
                        } else if !line.isEmpty {
                            print("ℹ️ [AIService] Ignored Line: \(line)")
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateAPIKey(_ key: String) async throws -> Bool {
        // Simple validation by listing models
        do {
            _ = try await fetchModels()
            return true
        } catch {
            return false
        }
    }
    
    func fetchModels() async throws -> [AIModel] {
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: URL(string: "\(cleanBaseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        print("🚀 [AIService] Fetching Models: \(request.url?.absoluteString ?? "")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.invalidResponse
        }

        struct ModelsResponse: Codable {
            struct ModelItem: Codable {
                let id: String
            }
            let data: [ModelItem]
        }

        let result = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return result.data.map { AIModel(id: $0.id) }
    }

    /// 根据优化后的内容生成简短标题
    /// - Parameter content: 优化后的提示词内容
    /// - Returns: 生成的标题（10-20字）
    func generateTitle(for content: String) async throws -> String {
        let systemPrompt = """
        你是一个标题生成专家。请根据用户提供的提示词内容，生成一个简短、准确、有描述性的标题。
        要求：
        1. 标题长度控制在10-20个字符
        2. 标题要能概括提示词的主要用途或目的
        3. 使用简洁的动词+名词结构
        4. 不要使用引号或其他特殊符号
        5. 只返回标题本身，不要有任何解释
        """

        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: URL(string: "\(cleanBaseURL)/chat/completions")!)

        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "model": model.id,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "请为以下提示词生成标题：\n\n\(content)"]
            ],
            "stream": false,
            "temperature": 0.5,
            "max_tokens": 50  // 标题不需要太长
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("🏷️ [AIService] Generating Title...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AIError.unauthorized
        case 429:
            throw AIError.rateLimitExceeded
        default:
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let title = result.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        // 清理标题：去除可能的引号和多余空白
        let cleanTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")

        print("🏷️ [AIService] Generated Title: \(cleanTitle)")

        return cleanTitle
    }
    
    private func createRequest(prompt: String, mode: OptimizeMode, stream: Bool) -> URLRequest {
        // Ensure baseURL doesn't have a trailing slash to avoid double slashes
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: URL(string: "\(cleanBaseURL)/chat/completions")!)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Add User-Agent to mimic a browser/legitimate client
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let body: [String: Any] = [

            "model": model.id,
            "messages": [
                ["role": "system", "content": mode.systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "stream": stream,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Debug Logging
        print("🚀 [AIService] Sending Request:")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        if let headers = request.allHTTPHeaderFields {
            var safeHeaders = headers
            if let _ = safeHeaders["Authorization"] {
                safeHeaders["Authorization"] = "Bearer sk-***"
            }
            print("Headers: \(safeHeaders)")
        }
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        
        return request
    }
}

// OpenAI 响应模型
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// 流式响应模型
struct StreamChunk: Codable {
    struct Choice: Codable {
        struct Delta: Codable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
