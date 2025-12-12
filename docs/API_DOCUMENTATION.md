# PromptCraft - API 接口文档

## 文档信息

- **项目名称**: PromptCraft
- **文档版本**: v1.0
- **创建日期**: 2025-12-02
- **最后更新**: 2025-12-02

---

## 目录

1. [概述](#1-概述)
2. [OpenAI API 集成](#2-openai-api-集成)
3. [内部服务 API](#3-内部服务-api)
4. [数据模型](#4-数据模型)
5. [错误处理](#5-错误处理)
6. [最佳实践](#6-最佳实践)

---

## 1. 概述

### 1.1 API 架构

PromptCraft 的 API 分为两层：

```
┌─────────────────────────────────────┐
│      External API (OpenAI)          │
│  - Chat Completions                 │
│  - Models                           │
└─────────────────────────────────────┘
              ↓ ↑
┌─────────────────────────────────────┐
│      Internal Service API           │
│  - AIService                        │
│  - StorageService                   │
│  - HotkeyService                    │
│  - ClipboardService                 │
│  - AnalyticsService                 │
└─────────────────────────────────────┘
```

### 1.2 认证方式

```swift
// OpenAI API 认证
Authorization: Bearer YOUR_API_KEY

// 内部服务无需认证（本地应用）
```

---

## 2. OpenAI API 集成

### 2.1 Chat Completions API

#### 2.1.1 创建对话补全

**端点**: `POST https://api.openai.com/v1/chat/completions`

**请求头**:
```http
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY
```

**请求体**:
```json
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "你是一个提示词优化专家..."
    },
    {
      "role": "user",
      "content": "帮我写一篇文章"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000,
  "stream": false
}
```

**响应**:
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-4",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "请帮我撰写一篇关于...的文章，要求：\n1. 字数约1000字\n2. 结构清晰..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 56,
    "completion_tokens": 150,
    "total_tokens": 206
  }
}
```

**Swift 实现**:
```swift
func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
    let url = URL(string: "\(baseURL)/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "model": model.rawValue,
        "messages": [
            ["role": "system", "content": mode.systemPrompt],
            ["role": "user", "content": prompt]
        ],
        "temperature": 0.7,
        "max_tokens": 2000,
        "stream": false
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw AIError.invalidResponse
    }
    
    let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
    return result.choices.first?.message.content ?? ""
}
```

#### 2.1.2 流式对话补全

**请求体**:
```json
{
  "model": "gpt-4",
  "messages": [...],
  "stream": true
}
```

**响应** (Server-Sent Events):
```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{"content":"请"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{"content":"帮"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]
```

**Swift 实现**:
```swift
func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let url = URL(string: "\(baseURL)/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "model": model.rawValue,
                "messages": [
                    ["role": "system", "content": mode.systemPrompt],
                    ["role": "user", "content": prompt]
                ],
                "stream": true
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw AIError.invalidResponse
                }
                
                for try await line in bytes.lines {
                    if line.hasPrefix("data: ") {
                        let data = line.dropFirst(6)
                        if data == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        
                        if let jsonData = data.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData),
                           let content = chunk.choices.first?.delta.content {
                            continuation.yield(content)
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

struct StreamChunk: Codable {
    struct Choice: Codable {
        struct Delta: Codable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
```

### 2.2 Models API

#### 2.2.1 列出可用模型

**端点**: `GET https://api.openai.com/v1/models`

**请求头**:
```http
Authorization: Bearer YOUR_API_KEY
```

**响应**:
```json
{
  "object": "list",
  "data": [
    {
      "id": "gpt-4",
      "object": "model",
      "created": 1687882411,
      "owned_by": "openai"
    },
    {
      "id": "gpt-3.5-turbo",
      "object": "model",
      "created": 1677610602,
      "owned_by": "openai"
    }
  ]
}
```

**Swift 实现**:
```swift
func listModels() async throws -> [AIModel] {
    let url = URL(string: "\(baseURL)/models")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
    
    return response.data.map { AIModel(id: $0.id, name: $0.id) }
}

struct ModelsResponse: Codable {
    struct Model: Codable {
        let id: String
        let object: String
        let created: Int
        let ownedBy: String
        
        enum CodingKeys: String, CodingKey {
            case id, object, created
            case ownedBy = "owned_by"
        }
    }
    let data: [Model]
}
```

### 2.3 错误响应

**错误格式**:
```json
{
  "error": {
    "message": "Invalid API key provided",
    "type": "invalid_request_error",
    "param": null,
    "code": "invalid_api_key"
  }
}
```

**常见错误码**:

| 状态码 | 错误类型 | 说明 |
|--------|---------|------|
| 401 | invalid_api_key | API Key 无效 |
| 429 | rate_limit_exceeded | 请求频率超限 |
| 500 | server_error | 服务器错误 |
| 503 | service_unavailable | 服务不可用 |

---

## 3. 内部服务 API

### 3.1 AIService

#### 3.1.1 优化提示词

```swift
protocol AIServiceProtocol {
    /// 优化提示词（同步）
    /// - Parameters:
    ///   - prompt: 原始提示词
    ///   - mode: 优化模式
    /// - Returns: 优化后的提示词
    /// - Throws: AIError
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String
    
    /// 优化提示词（流式）
    /// - Parameters:
    ///   - prompt: 原始提示词
    ///   - mode: 优化模式
    /// - Returns: 异步流，逐字返回优化结果
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AsyncThrowingStream<String, Error>
    
    /// 验证 API Key
    /// - Parameter key: API Key
    /// - Returns: 是否有效
    /// - Throws: AIError
    func validateAPIKey(_ key: String) async throws -> Bool
}
```

**使用示例**:
```swift
let aiService = OpenAIService(apiKey: "sk-xxx")

// 同步优化
let result = try await aiService.optimize(
    prompt: "帮我写一篇文章",
    mode: .detailed
)

// 流式优化
for try await chunk in aiService.optimizeStream(
    prompt: "帮我写一篇文章",
    mode: .detailed
) {
    print(chunk, terminator: "")
}
```

### 3.2 StorageService

#### 3.2.1 提示词 CRUD

```swift
class StorageService {
    /// 保存提示词
    /// - Parameter prompt: 提示词对象
    /// - Throws: StorageError
    func savePrompt(_ prompt: Prompt) throws
    
    /// 获取所有提示词
    /// - Returns: 提示词数组
    /// - Throws: StorageError
    func fetchPrompts() throws -> [Prompt]
    
    /// 按分类获取提示词
    /// - Parameter category: 分类
    /// - Returns: 提示词数组
    /// - Throws: StorageError
    func fetchPrompts(category: Category) throws -> [Prompt]
    
    /// 搜索提示词
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的提示词数组
    /// - Throws: StorageError
    func searchPrompts(query: String) throws -> [Prompt]
    
    /// 删除提示词
    /// - Parameter prompt: 要删除的提示词
    /// - Throws: StorageError
    func deletePrompt(_ prompt: Prompt) throws
    
    /// 更新提示词
    /// - Parameter prompt: 要更新的提示词
    /// - Throws: StorageError
    func updatePrompt(_ prompt: Prompt) throws
}
```

**使用示例**:
```swift
let storage = StorageService()

// 保存提示词
let prompt = Prompt(
    title: "代码审查",
    originalContent: "帮我审查代码",
    optimizedContent: "请帮我审查以下代码...",
    optimizeMode: .professional
)
try storage.savePrompt(prompt)

// 搜索提示词
let results = try storage.searchPrompts(query: "代码")

// 删除提示词
try storage.deletePrompt(prompt)
```

#### 3.2.2 分类管理

```swift
extension StorageService {
    /// 保存分类
    func saveCategory(_ category: Category) throws
    
    /// 获取所有分类
    func fetchCategories() throws -> [Category]
    
    /// 删除分类
    func deleteCategory(_ category: Category) throws
}
```

#### 3.2.3 数据导入导出

```swift
extension StorageService {
    /// 导出所有数据
    /// - Returns: JSON 数据
    /// - Throws: StorageError
    func exportData() throws -> Data
    
    /// 导入数据
    /// - Parameter data: JSON 数据
    /// - Throws: StorageError
    func importData(_ data: Data) throws
}
```

**导出数据格式**:
```json
{
  "exportDate": "2025-12-02T10:30:00Z",
  "version": "1.0",
  "prompts": [
    {
      "id": "uuid-1",
      "title": "代码审查",
      "originalContent": "帮我审查代码",
      "optimizedContent": "请帮我审查以下代码...",
      "optimizeMode": "professional",
      "category": "编程",
      "tags": ["工作", "代码"],
      "isFavorite": true,
      "usageCount": 5,
      "createdAt": "2025-12-01T10:00:00Z",
      "updatedAt": "2025-12-02T10:00:00Z"
    }
  ],
  "categories": [
    {
      "id": "uuid-2",
      "name": "编程",
      "icon": "chevron.left.forwardslash.chevron.right",
      "order": 2,
      "isSystem": true
    }
  ],
  "tags": [
    {
      "id": "uuid-3",
      "name": "工作",
      "color": "#007AFF"
    }
  ]
}
```

### 3.3 HotkeyService

```swift
class HotkeyService {
    /// 注册快捷键处理器
    /// - Parameters:
    ///   - onTogglePanel: 切换面板回调
    ///   - onQuickOptimize: 快速优化回调
    ///   - onOpenLibrary: 打开提示词本回调
    func registerHandlers(
        onTogglePanel: @escaping () -> Void,
        onQuickOptimize: @escaping () -> Void,
        onOpenLibrary: @escaping () -> Void
    )
    
    /// 检测快捷键冲突
    /// - Parameter shortcut: 快捷键
    /// - Returns: 冲突的应用列表
    func checkConflicts(for shortcut: KeyboardShortcuts.Shortcut) -> [String]
}
```

**使用示例**:
```swift
let hotkeyService = HotkeyService.shared

hotkeyService.registerHandlers(
    onTogglePanel: {
        print("切换面板")
    },
    onQuickOptimize: {
        print("快速优化")
    },
    onOpenLibrary: {
        print("打开提示词本")
    }
)
```

### 3.4 ClipboardService

```swift
class ClipboardService {
    /// 复制文本到剪贴板
    /// - Parameter text: 要复制的文本
    func copy(_ text: String)
    
    /// 从剪贴板粘贴文本
    /// - Returns: 剪贴板中的文本
    func paste() -> String?
    
    /// 检查剪贴板是否有文本
    /// - Returns: 是否有文本
    func hasText() -> Bool
}
```

**使用示例**:
```swift
let clipboard = ClipboardService.shared

// 复制
clipboard.copy("优化后的提示词")

// 粘贴
if let text = clipboard.paste() {
    print(text)
}
```

### 3.5 AnalyticsService

```swift
class AnalyticsService {
    /// 记录 API 调用
    /// - Parameter model: 使用的模型
    func recordAPICall(model: AIModel)
    
    /// 获取今日调用次数
    /// - Returns: 调用次数
    func getTodayCallCount() -> Int
    
    /// 获取本月调用次数
    /// - Returns: 调用次数
    func getMonthlyCallCount() -> Int
    
    /// 估算费用
    /// - Parameters:
    ///   - model: 模型
    ///   - tokenCount: Token 数量
    /// - Returns: 预估费用（美元）
    func estimateCost(model: AIModel, tokenCount: Int) -> Double
}
```

**使用示例**:
```swift
let analytics = AnalyticsService.shared

// 记录调用
analytics.recordAPICall(model: .gpt4)

// 获取统计
let todayCount = analytics.getTodayCallCount()
let monthlyCost = analytics.estimateCost(model: .gpt4, tokenCount: 1000)
```

---

## 4. 数据模型

### 4.1 Prompt（提示词）

```swift
@Model
final class Prompt {
    var id: UUID
    var title: String
    var originalContent: String
    var optimizedContent: String
    var optimizeMode: OptimizeMode
    var category: Category?
    var tags: [Tag]
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    
    init(
        title: String,
        originalContent: String,
        optimizedContent: String,
        optimizeMode: OptimizeMode,
        category: Category? = nil
    )
}
```

**JSON 表示**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "代码审查助手",
  "originalContent": "帮我审查代码",
  "optimizedContent": "请帮我审查以下代码，指出潜在问题...",
  "optimizeMode": "professional",
  "category": {
    "id": "...",
    "name": "编程"
  },
  "tags": [
    {"id": "...", "name": "工作", "color": "#007AFF"}
  ],
  "isFavorite": true,
  "usageCount": 12,
  "createdAt": "2025-12-01T10:00:00Z",
  "updatedAt": "2025-12-02T10:00:00Z",
  "lastUsedAt": "2025-12-02T09:30:00Z"
}
```

### 4.2 OptimizeMode（优化模式）

```swift
enum OptimizeMode: String, Codable, CaseIterable {
    case concise = "简洁版"
    case detailed = "详细版"
    case professional = "专业版"
    
    var systemPrompt: String {
        // 返回对应的系统提示词
    }
}
```

### 4.3 Category（分类）

```swift
@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var order: Int
    var isSystem: Bool
    var createdAt: Date
    
    init(name: String, icon: String, order: Int, isSystem: Bool = false)
}
```

### 4.4 Tag（标签）

```swift
@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String)
}
```

### 4.5 AppSettings（应用设置）

```swift
struct AppSettings: Codable {
    var theme: Theme
    var defaultOptimizeMode: OptimizeMode
    var launchAtLogin: Bool
    var showCopyToast: Bool
    var selectedModel: AIModel
    var customAPIEndpoint: String?
    var apiTimeout: TimeInterval
    var maxRetries: Int
    var dailyCallLimit: Int?
}
```

---

## 5. 错误处理

### 5.1 错误类型

#### AIError

```swift
enum AIError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case emptyResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case timeout
    case rateLimitExceeded
    case insufficientQuota
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key 无效，请检查设置"
        case .invalidResponse:
            return "服务器响应无效"
        case .emptyResponse:
            return "服务器返回空内容"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .timeout:
            return "请求超时，请稍后重试"
        case .rateLimitExceeded:
            return "请求频率超限，请稍后重试"
        case .insufficientQuota:
            return "API 配额不足"
        }
    }
}
```

#### StorageError

```swift
enum StorageError: LocalizedError {
    case cannotDeleteSystemCategory
    case dataCorrupted
    case saveFailed
    case fetchFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteSystemCategory:
            return "无法删除系统预置分类"
        case .dataCorrupted:
            return "数据已损坏"
        case .saveFailed:
            return "保存失败"
        case .fetchFailed:
            return "读取失败"
        case .deleteFailed:
            return "删除失败"
        }
    }
}
```

#### NetworkError

```swift
enum NetworkError: LocalizedError {
    case offline
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "网络连接不可用"
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .decodingError:
            return "数据解析失败"
        }
    }
}
```

### 5.2 错误处理示例

```swift
do {
    let result = try await aiService.optimize(
        prompt: inputText,
        mode: .detailed
    )
    optimizedText = result
} catch let error as AIError {
    switch error {
    case .invalidAPIKey:
        showAlert("请先配置 API Key")
    case .rateLimitExceeded:
        showAlert("请求过于频繁，请稍后重试")
    case .timeout:
        showAlert("请求超时，请检查网络连接")
    default:
        showAlert(error.localizedDescription)
    }
} catch {
    showAlert("未知错误: \(error.localizedDescription)")
}
```

---

## 6. 最佳实践

### 6.1 API 调用优化

#### 请求重试

```swift
func optimizeWithRetry(
    prompt: String,
    mode: OptimizeMode,
    maxRetries: Int = 3
) async throws -> String {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await optimize(prompt: prompt, mode: mode)
        } catch {
            lastError = error
            
            // 指数退避
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    
    throw lastError ?? AIError.networkError(NSError())
}
```

#### 请求取消

```swift
class OptimizeViewModel: ObservableObject {
    private var currentTask: Task<Void, Never>?
    
    func optimize() {
        // 取消之前的请求
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let result = try await aiService.optimize(
                    prompt: inputText,
                    mode: selectedMode
                )
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.optimizedText = result
                }
            } catch {
                // 处理错误
            }
        }
    }
}
```

### 6.2 数据缓存

```swift
class CachedAIService: AIServiceProtocol {
    private let service: AIServiceProtocol
    private let cache = NSCache<NSString, NSString>()
    
    init(service: AIServiceProtocol) {
        self.service = service
        cache.countLimit = 50
    }
    
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
        let cacheKey = "\(prompt)-\(mode.rawValue)" as NSString
        
        // 检查缓存
        if let cached = cache.object(forKey: cacheKey) {
            return cached as String
        }
        
        // 调用 API
        let result = try await service.optimize(prompt: prompt, mode: mode)
        
        // 缓存结果
        cache.setObject(result as NSString, forKey: cacheKey)
        
        return result
    }
}
```

### 6.3 请求限流

```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.0 // 1秒
    
    func waitIfNeeded() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                let delay = minimumInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}

// 使用
let rateLimiter = RateLimiter()

func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
    await rateLimiter.waitIfNeeded()
    return try await aiService.optimize(prompt: prompt, mode: mode)
}
```

### 6.4 Token 计数

```swift
extension String {
    /// 估算 Token 数量（粗略估计）
    var estimatedTokenCount: Int {
        // 英文：约 4 个字符 = 1 token
        // 中文：约 1.5 个字符 = 1 token
        let chineseCount = self.filter { $0 >= "\u{4E00}" && $0 <= "\u{9FFF}" }.count
        let otherCount = self.count - chineseCount
        
        return Int(Double(chineseCount) / 1.5 + Double(otherCount) / 4.0)
    }
}

// 使用
let prompt = "帮我写一篇文章"
let tokenCount = prompt.estimatedTokenCount
let cost = analytics.estimateCost(model: .gpt4, tokenCount: tokenCount)
```

### 6.5 批量操作

```swift
extension StorageService {
    /// 批量保存提示词
    func savePrompts(_ prompts: [Prompt]) throws {
        for prompt in prompts {
            modelContext.insert(prompt)
        }
        try modelContext.save()
    }
    
    /// 批量删除提示词
    func deletePrompts(_ prompts: [Prompt]) throws {
        for prompt in prompts {
            modelContext.delete(prompt)
        }
        try modelContext.save()
    }
}
```

---

## 附录

### A. API 速率限制

| 模型 | 免费版 | 付费版 |
|------|--------|--------|
| GPT-3.5 Turbo | 3 RPM | 3500 RPM |
| GPT-4 | - | 200 RPM |
| GPT-4 Turbo | - | 500 RPM |

*RPM = Requests Per Minute*

### B. Token 价格

| 模型 | 输入价格 | 输出价格 |
|------|---------|---------|
| GPT-3.5 Turbo | $0.0005/1K tokens | $0.0015/1K tokens |
| GPT-4 | $0.03/1K tokens | $0.06/1K tokens |
| GPT-4 Turbo | $0.01/1K tokens | $0.03/1K tokens |

### C. 常见问题

**Q: 如何处理 API 超时？**
A: 设置合理的超时时间（建议 30 秒），并实现重试机制。

**Q: 如何优化 API 调用成本？**
A: 
1. 使用缓存避免重复请求
2. 选择合适的模型（GPT-3.5 更便宜）
3. 控制 max_tokens 参数
4. 实现请求限流

**Q: 如何处理流式响应中断？**
A: 实现断点续传或重新请求机制。

### D. 参考资源

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [OpenAI API Best Practices](https://platform.openai.com/docs/guides/production-best-practices)
- [Rate Limits Guide](https://platform.openai.com/docs/guides/rate-limits)

---

*文档版本: v1.0*
*创建日期: 2025-12-02*
*维护者: 开发团队*
