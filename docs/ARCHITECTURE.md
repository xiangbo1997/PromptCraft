# PromptCraft - 技术架构文档

## 文档信息

- **项目名称**: PromptCraft
- **文档版本**: v1.0
- **创建日期**: 2025-12-02
- **最后更新**: 2025-12-02
- **文档状态**: 初稿

---

## 目录

1. [架构概览](#1-架构概览)
2. [技术栈](#2-技术栈)
3. [系统架构](#3-系统架构)
4. [模块设计](#4-模块设计)
5. [数据模型](#5-数据模型)
6. [核心服务](#6-核心服务)
7. [网络层设计](#7-网络层设计)
8. [存储方案](#8-存储方案)
9. [安全设计](#9-安全设计)
10. [性能优化](#10-性能优化)
11. [错误处理](#11-错误处理)
12. [测试策略](#12-测试策略)
13. [部署方案](#13-部署方案)

---

## 1. 架构概览

### 1.1 架构原则

- **MVVM 架构模式**: 使用 SwiftUI + Observation (@Observable) 实现响应式编程
- **模块化设计**: 功能模块独立，低耦合高内聚
- **协议导向**: 使用 Protocol 定义接口，便于扩展和测试
- **依赖注入**: 使用环境对象和依赖注入管理服务
- **单向数据流**: 状态管理遵循单向数据流原则

### 1.2 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Main UI    │  │  MenuBar UI  │  │  Settings UI │      │
│  │  (SwiftUI)   │  │  (SwiftUI)   │  │  (SwiftUI)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      ViewModel Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  OptimizeVM  │  │  LibraryVM   │  │  SettingsVM  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  AI Service  │  │Storage Service│ │ Hotkey Service│     │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │Clipboard Svc │  │Analytics Svc │  │ Network Svc  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  SwiftData   │  │  UserDefaults│  │   Keychain   │      │
│  │  (Prompts)   │  │  (Settings)  │  │  (API Keys)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 技术栈

### 2.1 开发环境

| 工具 | 版本 | 用途 |
|------|------|------|
| Xcode | 15.0+ | 开发 IDE |
| Swift | 5.9+ | 编程语言 |
| macOS SDK | 14.0+ | 系统 SDK |

### 2.2 核心框架

| 框架 | 用途 | 说明 |
|------|------|------|
| SwiftUI | UI 框架 | 声明式 UI 开发 |
| SwiftData | 数据持久化 | 本地数据库 |
| Observation | 响应式编程 | 替代 Combine，更现代的状态管理 |
| AppKit | 系统集成 | 菜单栏、快捷键等 |

### 2.3 第三方依赖

| 库名 | 版本 | 用途 | 许可证 |
|------|------|------|--------|
| KeyboardShortcuts | ~1.15 | 全局快捷键 | MIT |
| Sparkle | ~2.5 | 应用更新 | MIT |

### 2.4 开发工具

- **版本控制**: Git
- **包管理**: Swift Package Manager (SPM)
- **代码规范**: SwiftLint
- **文档生成**: DocC

---

## 3. 系统架构

### 3.1 应用生命周期

```swift
@main
struct PromptCraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        // 主窗口
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        
        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

### 3.2 AppDelegate 职责

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 初始化菜单栏
        setupStatusBar()
        
        // 2. 注册全局快捷键
        setupHotkeys()
        
        // 3. 检查首次启动
        checkFirstLaunch()
        
        // 4. 初始化服务
        initializeServices()
    }
}
```

### 3.3 应用状态管理

```swift
class AppState: ObservableObject {
    static let shared = AppState()
    
    // 全局状态
    @Published var isOnline: Bool = true
    @Published var currentTheme: Theme = .system
    @Published var apiKeyConfigured: Bool = false
    
    // 服务实例
    let aiService: AIServiceProtocol
    let storageService: StorageService
    let hotkeyService: HotkeyService
    let clipboardService: ClipboardService
    
    private init() {
        // 初始化服务
        self.aiService = OpenAIService()
        self.storageService = StorageService()
        self.hotkeyService = HotkeyService()
        self.clipboardService = ClipboardService()
    }
}
```

---

## 4. 模块设计

### 4.1 模块划分

```
PromptCraft/
├── App/                    # 应用入口
│   ├── PromptCraftApp.swift
│   └── AppDelegate.swift
│
├── Core/                   # 核心模块
│   ├── Models/            # 数据模型
│   ├── Services/          # 业务服务
│   └── Utils/             # 工具类
│
├── Features/              # 功能模块
│   ├── Optimize/          # 提示词优化
│   ├── Library/           # 提示词本
│   ├── MenuBar/           # 菜单栏
│   └── Settings/          # 设置
│
├── Shared/                # 共享组件
│   ├── Components/        # UI 组件
│   ├── Extensions/        # 扩展
│   └── Constants/         # 常量
│
└── Resources/             # 资源文件
    ├── Assets.xcassets
    └── Localizable.strings
```

### 4.2 功能模块详细设计

#### 4.2.1 Optimize 模块

```
Features/Optimize/
├── Views/
│   ├── OptimizeView.swift          # 主视图
│   ├── InputSection.swift          # 输入区域
│   ├── ModeSelector.swift          # 模式选择器
│   └── ResultSection.swift         # 结果展示
│
├── ViewModels/
│   └── OptimizeViewModel.swift     # 业务逻辑
│
└── Models/
    └── OptimizeRequest.swift       # 请求模型
```

**OptimizeViewModel 设计**:

```swift
@MainActor
class OptimizeViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var optimizedText: String = ""
    @Published var selectedMode: OptimizeMode = .detailed
    @Published var isOptimizing: Bool = false
    @Published var error: AppError?
    
    private let aiService: AIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }
    
    // 优化提示词
    func optimize() async {
        guard !inputText.isEmpty else { return }
        
        isOptimizing = true
        defer { isOptimizing = false }
        
        do {
            optimizedText = try await aiService.optimize(
                prompt: inputText,
                mode: selectedMode
            )
        } catch {
            self.error = AppError.from(error)
        }
    }
    
    // 流式优化
    func optimizeStreaming() {
        aiService.optimizeStream(prompt: inputText, mode: selectedMode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isOptimizing = false
                },
                receiveValue: { [weak self] chunk in
                    self?.optimizedText += chunk
                }
            )
            .store(in: &cancellables)
    }
}
```

#### 4.2.2 Library 模块

```
Features/Library/
├── Views/
│   ├── LibraryView.swift           # 主视图
│   ├── PromptListView.swift        # 列表视图
│   ├── PromptCardView.swift        # 卡片视图
│   ├── SearchBar.swift             # 搜索栏
│   └── FilterPanel.swift           # 筛选面板
│
├── ViewModels/
│   └── LibraryViewModel.swift      # 业务逻辑
│
└── Models/
    └── PromptFilter.swift          # 筛选模型
```

**LibraryViewModel 设计**:

```swift
@MainActor
class LibraryViewModel: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var filteredPrompts: [Prompt] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category?
    @Published var selectedTags: Set<Tag> = []
    @Published var sortOption: SortOption = .lastUsed
    
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    
    init(storageService: StorageService) {
        self.storageService = storageService
        setupBindings()
        loadPrompts()
    }
    
    private func setupBindings() {
        // 监听搜索和筛选变化
        Publishers.CombineLatest4(
            $prompts,
            $searchText,
            $selectedCategory,
            $selectedTags
        )
        .debounce(for: 0.3, scheduler: DispatchQueue.main)
        .map { [weak self] prompts, search, category, tags in
            self?.filterPrompts(prompts, search, category, tags) ?? []
        }
        .assign(to: &$filteredPrompts)
    }
    
    private func filterPrompts(
        _ prompts: [Prompt],
        _ search: String,
        _ category: Category?,
        _ tags: Set<Tag>
    ) -> [Prompt] {
        var result = prompts
        
        // 搜索过滤
        if !search.isEmpty {
            result = result.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(search) ||
                prompt.optimizedContent.localizedCaseInsensitiveContains(search)
            }
        }
        
        // 分类过滤
        if let category = category {
            result = result.filter { $0.category == category }
        }
        
        // 标签过滤
        if !tags.isEmpty {
            result = result.filter { prompt in
                !Set(prompt.tags).isDisjoint(with: tags)
            }
        }
        
        // 排序
        return sortPrompts(result, by: sortOption)
    }
}
```

#### 4.2.3 MenuBar 模块

```
Features/MenuBar/
├── StatusBarController.swift       # 菜单栏控制器
├── MenuBarPopover.swift            # 弹出面板
└── Views/
    ├── QuickOptimizeView.swift     # 快速优化
    └── RecentPromptsView.swift     # 最近使用
```

**StatusBarController 设计**:

```swift
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "PromptCraft")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem.button else { return }
        
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        popover.contentViewController?.view.window?.makeKey()
    }
}
```

---

## 5. 数据模型

### 5.1 核心数据模型

```swift
import SwiftData
import Foundation

// 提示词
@Model
final class Prompt {
    @Attribute(.unique) var id: UUID
    var title: String
    var originalContent: String
    var optimizedContent: String
    var optimizeMode: OptimizeMode
    
    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .cascade) var tags: [Tag]
    
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
    ) {
        self.id = UUID()
        self.title = title
        self.originalContent = originalContent
        self.optimizedContent = optimizedContent
        self.optimizeMode = optimizeMode
        self.category = category
        self.tags = []
        self.isFavorite = false
        self.usageCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 增加使用次数
    func incrementUsage() {
        usageCount += 1
        lastUsedAt = Date()
        updatedAt = Date()
    }
}

// 优化模式
enum OptimizeMode: String, Codable, CaseIterable {
    case concise = "简洁版"
    case detailed = "详细版"
    case professional = "专业版"
    
    var systemPrompt: String {
        switch self {
        case .concise:
            return """
            你是一个提示词优化专家。请将用户的输入优化为简洁、精准的提示词。
            要求：
            1. 保留核心意图
            2. 去除冗余表达
            3. 使用精准动词
            4. 字数控制在50字以内
            """
        case .detailed:
            return """
            你是一个提示词优化专家。请将用户的输入优化为详细、完整的提示词。
            要求：
            1. 补充背景信息和上下文
            2. 明确输出格式要求
            3. 添加必要的约束条件
            4. 指定语气和风格
            """
        case .professional:
            return """
            你是一个提示词优化专家。请将用户的输入优化为专业、结构化的提示词。
            要求：
            1. 包含角色设定
            2. 明确任务目标
            3. 提供思考步骤
            4. 指定输出格式
            5. 给出示例（如适用）
            """
        }
    }
}

// 分类
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var order: Int
    var isSystem: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Prompt.category)
    var prompts: [Prompt]?
    
    init(name: String, icon: String, order: Int, isSystem: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.order = order
        self.isSystem = isSystem
        self.createdAt = Date()
    }
}

// 标签
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
}
```

### 5.2 设置模型

```swift
import Foundation

// 应用设置
struct AppSettings: Codable {
    var theme: Theme = .system
    var defaultOptimizeMode: OptimizeMode = .detailed
    var launchAtLogin: Bool = false
    var showCopyToast: Bool = true
    var selectedModel: AIModel = .gpt4
    var customAPIEndpoint: String?
    var apiTimeout: TimeInterval = 30
    var maxRetries: Int = 3
    var dailyCallLimit: Int?
    
    // 存储键
    static let storageKey = "app_settings"
    
    // 加载设置
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    // 保存设置
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.storageKey)
        }
    }
}

// 主题
enum Theme: String, Codable, CaseIterable {
    case light = "浅色"
    case dark = "深色"
    case system = "跟随系统"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// AI 模型
enum AIModel: String, Codable, CaseIterable {
    case gpt35Turbo = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    case gpt4Turbo = "gpt-4-turbo-preview"
    
    var displayName: String {
        switch self {
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        case .gpt4: return "GPT-4"
        case .gpt4Turbo: return "GPT-4 Turbo"
        }
    }
    
    var maxTokens: Int {
        switch self {
        case .gpt35Turbo: return 4096
        case .gpt4: return 8192
        case .gpt4Turbo: return 128000
        }
    }
}

// 快捷键设置
struct HotkeySettings: Codable {
    var togglePanel: KeyCombo = KeyCombo(key: .p, modifiers: [.command, .shift])
    var quickOptimize: KeyCombo = KeyCombo(key: .o, modifiers: [.command, .shift])
    var openLibrary: KeyCombo = KeyCombo(key: .l, modifiers: [.command, .shift])
    
    static let storageKey = "hotkey_settings"
}

// 按键组合
struct KeyCombo: Codable, Hashable {
    var key: Key
    var modifiers: Set<Modifier>
    
    enum Key: String, Codable {
        case p, o, l
        // 可扩展更多按键
    }
    
    enum Modifier: String, Codable {
        case command, shift, option, control
    }
}
```

---

## 6. 核心服务

### 6.1 AI 服务

```swift
// AI 服务协议
protocol AIServiceProtocol {
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AnyPublisher<String, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
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
    
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AnyPublisher<String, Error> {
        let request = createRequest(prompt: prompt, mode: mode, stream: true)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                // 解析 SSE 流式响应
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw AIError.invalidResponse
                }
                
                let text = String(data: data, encoding: .utf8) ?? ""
                return self.parseStreamChunk(text)
            }
            .eraseToAnyPublisher()
    }
    
    func validateAPIKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        return httpResponse.statusCode == 200
    }
    
    private func createRequest(prompt: String, mode: OptimizeMode, stream: Bool) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model.rawValue,
            "messages": [
                ["role": "system", "content": mode.systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "stream": stream,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func parseStreamChunk(_ text: String) -> String {
        // 解析 SSE 格式的流式数据
        // data: {"choices":[{"delta":{"content":"..."}}]}
        // 实现省略
        return ""
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

// AI 错误类型
enum AIError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case emptyResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case timeout
    
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
        }
    }
}
```

### 6.2 存储服务

```swift
import SwiftData

class StorageService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() {
        do {
            let schema = Schema([
                Prompt.self,
                Category.self,
                Tag.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("无法初始化数据库: \(error)")
        }
    }
    
    // MARK: - Prompt CRUD
    
    func savePrompt(_ prompt: Prompt) throws {
        modelContext.insert(prompt)
        try modelContext.save()
    }
    
    func fetchPrompts() throws -> [Prompt] {
        let descriptor = FetchDescriptor<Prompt>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPrompts(category: Category) throws -> [Prompt] {
        let predicate = #Predicate<Prompt> { prompt in
            prompt.category == category
        }
        let descriptor = FetchDescriptor<Prompt>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func searchPrompts(query: String) throws -> [Prompt] {
        let predicate = #Predicate<Prompt> { prompt in
            prompt.title.localizedStandardContains(query) ||
            prompt.optimizedContent.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Prompt>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    func deletePrompt(_ prompt: Prompt) throws {
        modelContext.delete(prompt)
        try modelContext.save()
    }
    
    func updatePrompt(_ prompt: Prompt) throws {
        prompt.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - Category CRUD
    
    func saveCategory(_ category: Category) throws {
        modelContext.insert(category)
        try modelContext.save()
    }
    
    func fetchCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.order)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func deleteCategory(_ category: Category) throws {
        guard !category.isSystem else {
            throw StorageError.cannotDeleteSystemCategory
        }
        modelContext.delete(category)
        try modelContext.save()
    }
    
    // MARK: - Tag CRUD
    
    func saveTag(_ tag: Tag) throws {
        modelContext.insert(tag)
        try modelContext.save()
    }
    
    func fetchTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 数据导入导出
    
    func exportData() throws -> Data {
        let prompts = try fetchPrompts()
        let categories = try fetchCategories()
        let tags = try fetchTags()
        
        let exportData = ExportData(
            prompts: prompts,
            categories: categories,
            tags: tags,
            exportDate: Date()
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    func importData(_ data: Data) throws {
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // 导入分类
        for category in importData.categories {
            try saveCategory(category)
        }
        
        // 导入标签
        for tag in importData.tags {
            try saveTag(tag)
        }
        
        // 导入提示词
        for prompt in importData.prompts {
            try savePrompt(prompt)
        }
    }
    
    // MARK: - 预置数据
    
    func setupDefaultCategories() throws {
        let defaultCategories = [
            Category(name: "通用", icon: "star.fill", order: 0, isSystem: true),
            Category(name: "写作", icon: "pencil", order: 1, isSystem: true),
            Category(name: "编程", icon: "chevron.left.forwardslash.chevron.right", order: 2, isSystem: true),
            Category(name: "翻译", icon: "globe", order: 3, isSystem: true),
            Category(name: "营销", icon: "megaphone.fill", order: 4, isSystem: true),
            Category(name: "学习", icon: "book.fill", order: 5, isSystem: true),
            Category(name: "工作", icon: "briefcase.fill", order: 6, isSystem: true)
        ]
        
        for category in defaultCategories {
            try saveCategory(category)
        }
    }
}

// 导出数据模型
struct ExportData: Codable {
    let prompts: [Prompt]
    let categories: [Category]
    let tags: [Tag]
    let exportDate: Date
}

// 存储错误
enum StorageError: LocalizedError {
    case cannotDeleteSystemCategory
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteSystemCategory:
            return "无法删除系统预置分类"
        case .dataCorrupted:
            return "数据已损坏"
        }
    }
}
```

### 6.3 快捷键服务

```swift
import KeyboardShortcuts

class HotkeyService {
    static let shared = HotkeyService()
    
    // 快捷键名称
    extension KeyboardShortcuts.Name {
        static let togglePanel = Self("togglePanel")
        static let quickOptimize = Self("quickOptimize")
        static let openLibrary = Self("openLibrary")
    }
    
    private init() {
        setupDefaultShortcuts()
    }
    
    func setupDefaultShortcuts() {
        KeyboardShortcuts.setShortcut(
            .init(.p, modifiers: [.command, .shift]),
            for: .togglePanel
        )
        
        KeyboardShortcuts.setShortcut(
            .init(.o, modifiers: [.command, .shift]),
            for: .quickOptimize
        )
        
        KeyboardShortcuts.setShortcut(
            .init(.l, modifiers: [.command, .shift]),
            for: .openLibrary
        )
    }
    
    func registerHandlers(
        onTogglePanel: @escaping () -> Void,
        onQuickOptimize: @escaping () -> Void,
        onOpenLibrary: @escaping () -> Void
    ) {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) {
            onTogglePanel()
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickOptimize) {
            onQuickOptimize()
        }
        
        KeyboardShortcuts.onKeyUp(for: .openLibrary) {
            onOpenLibrary()
        }
    }
    
    func checkConflicts(for shortcut: KeyboardShortcuts.Shortcut) -> [String] {
        // 检测与系统快捷键的冲突
        // 实现省略
        return []
    }
}
```

### 6.4 剪贴板服务

```swift
import AppKit

class ClipboardService {
    static let shared = ClipboardService()
    
    private let pasteboard = NSPasteboard.general
    
    func copy(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func paste() -> String? {
        return pasteboard.string(forType: .string)
    }
    
    func hasText() -> Bool {
        return pasteboard.string(forType: .string) != nil
    }
}
```

### 6.5 分析服务

```swift
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private var callCount: [String: Int] = [:]
    private let storageKey = "analytics_data"
    
    private init() {
        loadData()
    }
    
    func recordAPICall(model: AIModel) {
        let key = "\(Date().formatted(.dateTime.year().month().day()))-\(model.rawValue)"
        callCount[key, default: 0] += 1
        saveData()
    }
    
    func getTodayCallCount() -> Int {
        let today = Date().formatted(.dateTime.year().month().day())
        return callCount.filter { $0.key.hasPrefix(today) }
            .values
            .reduce(0, +)
    }
    
    func getMonthlyCallCount() -> Int {
        let month = Date().formatted(.dateTime.year().month())
        return callCount.filter { $0.key.hasPrefix(month) }
            .values
            .reduce(0, +)
    }
    
    func estimateCost(model: AIModel, tokenCount: Int) -> Double {
        // 根据模型和 token 数量估算费用
        let pricePerToken: Double
        switch model {
        case .gpt35Turbo:
            pricePerToken = 0.000002 // $0.002 per 1K tokens
        case .gpt4:
            pricePerToken = 0.00003 // $0.03 per 1K tokens
        case .gpt4Turbo:
            pricePerToken = 0.00001 // $0.01 per 1K tokens
        }
        
        return Double(tokenCount) * pricePerToken
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(callCount) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return
        }
        callCount = decoded
    }
}
```

---

## 7. 网络层设计

### 7.1 网络管理器

```swift
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let reachability: NetworkReachability
    
    @Published var isOnline: Bool = true
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: config)
        self.reachability = NetworkReachability()
        
        setupReachability()
    }
    
    private func setupReachability() {
        reachability.whenReachable = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isOnline = true
            }
        }
        
        reachability.whenUnreachable = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isOnline = false
            }
        }
        
        try? reachability.startNotifier()
    }
    
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        guard isOnline else {
            throw NetworkError.offline
        }
        
        let request = try endpoint.asURLRequest()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// 端点协议
protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    
    func asURLRequest() throws -> URLRequest
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: LocalizedError {
    case offline
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "网络连接不可用"
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

---

## 8. 存储方案

### 8.1 存储架构

```
数据存储层级：
├── SwiftData (主数据库)
│   ├── Prompts
│   ├── Categories
│   └── Tags
│
├── UserDefaults (应用设置)
│   ├── AppSettings
│   ├── HotkeySettings
│   └── Analytics
│
└── Keychain (敏感数据)
    └── API Keys
```

### 8.2 Keychain 管理

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.promptcraft.app"
    
    func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 先删除旧值
        SecItemDelete(query as CFDictionary)
        
        // 添加新值
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status: status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "保存失败: \(status)"
        case .loadFailed(let status):
            return "加载失败: \(status)"
        case .deleteFailed(let status):
            return "删除失败: \(status)"
        case .invalidData:
            return "数据无效"
        }
    }
}
```

### 8.3 数据备份

```swift
class BackupManager {
    static let shared = BackupManager()
    
    private let backupDirectory: URL
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        self.backupDirectory = appSupport
            .appendingPathComponent("PromptCraft")
            .appendingPathComponent("Backups")
        
        try? FileManager.default.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func createBackup() throws -> URL {
        let data = try storageService.exportData()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "backup_\(formatter.string(from: Date())).json"
        
        let fileURL = backupDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    func restoreBackup(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try storageService.importData(data)
    }
    
    func listBackups() throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        return files.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
        }
    }
    
    func deleteOldBackups(keepLast count: Int = 5) throws {
        let backups = try listBackups()
        guard backups.count > count else { return }
        
        for backup in backups.dropFirst(count) {
            try FileManager.default.removeItem(at: backup)
        }
    }
    
    func scheduleAutoBackup() {
        // 每周自动备份
        Timer.scheduledTimer(withTimeInterval: 7 * 24 * 60 * 60, repeats: true) { [weak self] _ in
            try? self?.createBackup()
            try? self?.deleteOldBackups()
        }
    }
}
```

---

## 9. 安全设计

### 9.1 安全措施

| 安全项 | 实现方案 |
|--------|----------|
| API Key 存储 | 使用 Keychain 加密存储 |
| 本地数据 | SwiftData 加密存储（可选） |
| 网络通信 | 强制 HTTPS，证书验证 |
| 敏感日志 | 过滤 API Key 等敏感信息 |
| 权限最小化 | 仅请求必要的系统权限 |

### 9.2 数据加密

```swift
import CryptoKit

class EncryptionManager {
    static let shared = EncryptionManager()
    
    private let key: SymmetricKey
    
    private init() {
        // 从 Keychain 加载或生成加密密钥
        if let keyData = try? KeychainManager.shared.load(key: "encryption_key"),
           let data = Data(base64Encoded: keyData) {
            self.key = SymmetricKey(data: data)
        } else {
            self.key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }.base64EncodedString()
            try? KeychainManager.shared.save(key: "encryption_key", value: keyData)
        }
    }
    
    func encrypt(_ text: String) throws -> Data {
        let data = text.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
}
```

---

## 10. 性能优化

### 10.1 优化策略

| 优化项 | 实现方案 |
|--------|----------|
| 列表渲染 | LazyVStack + 虚拟滚动 |
| 搜索性能 | 防抖 + 后台线程 |
| 图片加载 | 异步加载 + 缓存 |
| 内存管理 | 弱引用 + 及时释放 |
| 启动优化 | 延迟加载非关键模块 |

### 10.2 搜索优化

```swift
class SearchManager {
    private var searchTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 0.3
    
    func search(
        query: String,
        in prompts: [Prompt]
    ) async -> [Prompt] {
        // 取消之前的搜索任务
        searchTask?.cancel()
        
        // 创建新的搜索任务
        searchTask = Task {
            // 防抖延迟
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // 在后台线程执行搜索
            return await Task.detached {
                prompts.filter { prompt in
                    prompt.title.localizedCaseInsensitiveContains(query) ||
                    prompt.optimizedContent.localizedCaseInsensitiveContains(query)
                }
            }.value
        }
        
        return await searchTask?.value ?? []
    }
}
```

### 10.3 缓存策略

```swift
class CacheManager {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, AnyObject>()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func set<T: AnyObject>(_ value: T, forKey key: String) {
        cache.setObject(value, forKey: key as NSString)
    }
    
    func get<T: AnyObject>(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
```

---

## 11. 错误处理

### 11.1 错误类型定义

```swift
enum AppError: LocalizedError {
    case ai(AIError)
    case storage(StorageError)
    case network(NetworkError)
    case keychain(KeychainError)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .ai(let error):
            return error.errorDescription
        case .storage(let error):
            return error.errorDescription
        case .network(let error):
            return error.errorDescription
        case .keychain(let error):
            return error.errorDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    static func from(_ error: Error) -> AppError {
        if let aiError = error as? AIError {
            return .ai(aiError)
        } else if let storageError = error as? StorageError {
            return .storage(storageError)
        } else if let networkError = error as? NetworkError {
            return .network(networkError)
        } else if let keychainError = error as? KeychainError {
            return .keychain(keychainError)
        } else {
            return .unknown(error)
        }
    }
}
```

### 11.2 错误处理中间件

```swift
class ErrorHandler {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    
    func handle(_ error: Error) {
        let appError = AppError.from(error)
        
        // 记录错误日志
        logError(appError)
        
        // 显示错误提示
        DispatchQueue.main.async {
            self.currentError = appError
        }
    }
    
    private func logError(_ error: AppError) {
        let logger = Logger(subsystem: "com.promptcraft.app", category: "error")
        logger.error("\(error.errorDescription ?? "Unknown error")")
    }
}
```

---

## 12. 测试策略

### 12.1 测试金字塔

```
        ┌─────────────┐
        │  UI Tests   │  10%
        ├─────────────┤
        │Integration  │  20%
        │   Tests     │
        ├─────────────┤
        │    Unit     │  70%
        │   Tests     │
        └─────────────┘
```

### 12.2 单元测试示例

```swift
import XCTest
@testable import PromptCraft

class OptimizeViewModelTests: XCTestCase {
    var viewModel: OptimizeViewModel!
    var mockAIService: MockAIService!
    
    override func setUp() {
        super.setUp()
        mockAIService = MockAIService()
        viewModel = OptimizeViewModel(aiService: mockAIService)
    }
    
    func testOptimizeSuccess() async throws {
        // Given
        viewModel.inputText = "帮我写一篇文章"
        mockAIService.mockResponse = "请帮我撰写一篇关于...的文章"
        
        // When
        await viewModel.optimize()
        
        // Then
        XCTAssertEqual(viewModel.optimizedText, mockAIService.mockResponse)
        XCTAssertFalse(viewModel.isOptimizing)
        XCTAssertNil(viewModel.error)
    }
    
    func testOptimizeEmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.optimize()
        
        // Then
        XCTAssertTrue(viewModel.optimizedText.isEmpty)
    }
}

// Mock AI Service
class MockAIService: AIServiceProtocol {
    var mockResponse: String = ""
    var shouldThrowError: Bool = false
    
    func optimize(prompt: String, mode: OptimizeMode) async throws -> String {
        if shouldThrowError {
            throw AIError.invalidResponse
        }
        return mockResponse
    }
    
    func optimizeStream(prompt: String, mode: OptimizeMode) -> AnyPublisher<String, Error> {
        Just(mockResponse)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func validateAPIKey(_ key: String) async throws -> Bool {
        return !shouldThrowError
    }
}
```

---

## 13. 部署方案

### 13.1 构建配置

```swift
// Debug 配置
#if DEBUG
let apiBaseURL = "https://api.openai.com/v1"
let enableLogging = true
#else
// Release 配置
let apiBaseURL = "https://api.openai.com/v1"
let enableLogging = false
#endif
```

### 13.2 版本管理

```
版本号规则: Major.Minor.Patch
- Major: 重大功能更新或架构变更
- Minor: 新功能添加
- Patch: Bug 修复和小优化

示例:
- v1.0.0: 首个正式版本
- v1.1.0: 添加流式输出功能
- v1.1.1: 修复搜索 bug
```

### 13.3 发布流程

```
1. 代码审查
   ├── 功能测试
   ├── 性能测试
   └── 安全审查

2. 构建打包
   ├── 清理缓存
   ├── 运行测试
   ├── Archive 构建
   └── 代码签名

3. 分发
   ├── 生成 DMG
   ├── 公证 (Notarization)
   └── 上传到分发渠道

4. 发布
   ├── 更新文档
   ├── 发布说明
   └── 用户通知
```

---

## 附录

### A. 项目依赖

```swift
// Package.swift
let package = Package(
    name: "PromptCraft",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.15.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0")
    ],
    targets: [
        .target(
            name: "PromptCraft",
            dependencies: [
                "KeyboardShortcuts",
                "Sparkle"
            ]
        ),
        .testTarget(
            name: "PromptCraftTests",
            dependencies: ["PromptCraft"]
        )
    ]
)
```

### B. 代码规范

- 遵循 Swift API Design Guidelines
- 使用 SwiftLint 进行代码检查
- 命名规范：
  - 类型：PascalCase
  - 变量/函数：camelCase
  - 常量：camelCase 或 UPPER_SNAKE_CASE
  - 协议：名词或形容词，如 `Codable`, `Equatable`

### C. Git 工作流

```
main (生产分支)
  ├── develop (开发分支)
  │   ├── feature/optimize-ui
  │   ├── feature/add-streaming
  │   └── bugfix/search-crash
  └── hotfix/critical-bug
```

---

*文档版本: v1.0*
*创建日期: 2025-12-02*
*最后更新: 2025-12-02*
*维护者: 开发团队*
