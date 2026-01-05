import Foundation

// MARK: - 内置 API 服务
/// 为用户提供零配置的 AI 服务，无需自己的 API Key
/// Pro 用户享受更高配额和优先响应
/// 注意：需要部署代理服务才能使用，否则请使用自定义 API 模式
@MainActor
class BuiltInAIService: AIServiceProtocol {

    private let subscriptionService: SubscriptionService
    private let baseURL: String
    private let timeout: TimeInterval
    private let session: URLSession

    // 内置服务配置（实际部署时应使用服务端代理）
    // 重要：这是占位符地址，实际使用前需要替换为真实的代理服务地址
    // 或者配置为 OpenAI 兼容的 API 地址
    private static let proxyBaseURL = "https://api.openai.com/v1"

    // 内置 API Key（用于演示，实际应使用环境变量或服务端代理）
    // 警告：不要在生产环境中硬编码 API Key
    private static let builtInAPIKey: String? = nil  // 设置为 nil 表示需要用户配置

    // 模型配置 - 所有用户都使用最好的模型
    private var model: String {
        return "gpt-4o"  // 移除 Pro 限制，所有用户使用 gpt-4o
    }

    init(subscriptionService: SubscriptionService = .shared, timeout: TimeInterval = 60) {
        self.subscriptionService = subscriptionService
        self.baseURL = Self.proxyBaseURL
        self.timeout = timeout

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - AIServiceProtocol

    func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
        // 检查是否有可用的 API Key
        guard Self.builtInAPIKey != nil else {
            throw AIError.configurationError("内置服务暂未配置，请在设置中切换到「自定义 API」模式并输入您的 API Key")
        }

        let request = try createRequest(prompt: prompt, mode: mode, stream: false)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            try handleHTTPError(httpResponse)

            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = result.choices.first?.message.content else {
                throw AIError.emptyResponse
            }

            return content
        } catch let error as URLError {
            throw AIError.networkError(error.localizedDescription)
        }
    }

    func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // 检查是否有可用的 API Key
                guard Self.builtInAPIKey != nil else {
                    continuation.finish(throwing: AIError.configurationError("内置服务暂未配置，请在设置中切换到「自定义 API」模式并输入您的 API Key"))
                    return
                }

                do {
                    let request = try createRequest(prompt: prompt, mode: mode, stream: true)
                    let (bytes, response) = try await session.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse {
                        try handleHTTPError(httpResponse)
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = line.dropFirst(6)
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            if let jsonData = data.data(using: .utf8) {
                                do {
                                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                                    if let content = chunk.choices.first?.delta.content {
                                        continuation.yield(content)
                                    }
                                } catch {
                                    // 忽略解析错误，继续处理
                                }
                            }
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
        // 内置服务不需要验证 API Key
        return true
    }

    func fetchModels() async throws -> [AIModel] {
        // 返回内置支持的模型
        return [
            AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini (免费)"),
            AIModel(id: "gpt-4o", name: "GPT-4o (Pro)")
        ]
    }

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

        let request = try createTitleRequest(systemPrompt: systemPrompt, content: content)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        try handleHTTPError(httpResponse)

        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let title = result.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
    }

    // MARK: - Private Methods

    private func createRequest(prompt: String, mode: OptimizeMode, stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // 添加用户标识用于配额追踪
        request.setValue(getUserIdentifier(), forHTTPHeaderField: "X-User-ID")
        request.setValue(subscriptionService.isPro ? "pro" : "free", forHTTPHeaderField: "X-User-Plan")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": mode.systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "stream": stream,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func createTitleRequest(systemPrompt: String, content: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getUserIdentifier(), forHTTPHeaderField: "X-User-ID")
        request.setValue(subscriptionService.isPro ? "pro" : "free", forHTTPHeaderField: "X-User-Plan")

        let body: [String: Any] = [
            "model": "gpt-4o-mini", // 标题生成用小模型即可
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "请为以下提示词生成标题：\n\n\(content)"]
            ],
            "stream": false,
            "temperature": 0.5,
            "max_tokens": 50
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func handleHTTPError(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw AIError.unauthorized
        case 429:
            throw AIError.rateLimitExceeded
        default:
            throw AIError.httpError(statusCode: response.statusCode)
        }
    }

    private func getUserIdentifier() -> String {
        // 获取或生成用户唯一标识
        let key = "user_unique_identifier"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}

// MARK: - API 服务模式
enum APIServiceMode: String, Codable, CaseIterable {
    case builtin = "builtin"    // 内置服务（零配置）
    case custom = "custom"      // 自定义 API Key

    var displayName: String {
        switch self {
        case .builtin: return "内置服务"
        case .custom: return "自定义 API"
        }
    }

    var description: String {
        switch self {
        case .builtin: return "无需配置，开箱即用"
        case .custom: return "使用自己的 API Key"
        }
    }
}

// MARK: - API 服务管理器
@MainActor
@Observable
final class APIServiceManager {

    static let shared = APIServiceManager()

    private(set) var currentMode: APIServiceMode = .custom  // 默认使用自定义模式，需要用户配置 API Key
    private(set) var customAPIKey: String = ""
    private(set) var customBaseURL: String = "https://api.openai.com/v1"
    private(set) var customModel: AIModel = .gpt4

    private let modeKey = "api_service_mode"
    // 使用与 SettingsViewModel 相同的键名以保持兼容
    private let apiKeyKey = "api_key"
    private let baseURLKey = "custom_base_url"
    private let modelKey = "custom_model_id"
    // 兼容 AppSettings 中的配置
    private let appSettingsKey = "app_settings"

    private init() {
        loadSettings()
    }

    // MARK: - 获取当前 AI 服务

    func getAIService() -> AIServiceProtocol {
        // 始终重新加载配置，确保使用最新的设置
        loadSettings()

        switch currentMode {
        case .builtin:
            return BuiltInAIService()
        case .custom:
            return OpenAIService(
                apiKey: customAPIKey,
                model: customModel,
                baseURL: customBaseURL
            )
        }
    }

    // MARK: - 设置方法

    func setMode(_ mode: APIServiceMode) {
        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
    }

    func setCustomAPIKey(_ key: String) {
        customAPIKey = key
        // 安全存储（实际应使用 Keychain）
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    func setCustomBaseURL(_ url: String) {
        customBaseURL = url
        UserDefaults.standard.set(url, forKey: baseURLKey)
    }

    func setCustomModel(_ model: AIModel) {
        customModel = model
        UserDefaults.standard.set(model.id, forKey: modelKey)
    }

    // MARK: - Private

    private func loadSettings() {
        if let modeString = UserDefaults.standard.string(forKey: modeKey),
           let mode = APIServiceMode(rawValue: modeString) {
            currentMode = mode
        }

        // 从 SettingsViewModel 兼容的键读取 API Key
        customAPIKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""

        // 从 AppSettings 读取 baseURL 和 model（与 SettingsViewModel 保持一致）
        if let data = UserDefaults.standard.data(forKey: appSettingsKey) {
            struct AppSettingsCompat: Codable {
                var selectedModelId: String?
                var customAPIEndpoint: String?
            }
            if let settings = try? JSONDecoder().decode(AppSettingsCompat.self, from: data) {
                if let endpoint = settings.customAPIEndpoint, !endpoint.isEmpty {
                    customBaseURL = endpoint
                } else {
                    customBaseURL = "https://api.openai.com/v1"
                }
                if let modelId = settings.selectedModelId {
                    customModel = AIModel(id: modelId)
                }
            }
        } else {
            // 回退到独立键
            customBaseURL = UserDefaults.standard.string(forKey: baseURLKey) ?? "https://api.openai.com/v1"
            if let modelId = UserDefaults.standard.string(forKey: modelKey) {
                customModel = AIModel(id: modelId)
            }
        }
    }
}
