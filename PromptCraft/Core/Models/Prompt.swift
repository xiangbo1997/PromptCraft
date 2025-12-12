import SwiftData
import Foundation

// 提示词
@Model
final class Prompt: Codable {
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

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, originalContent, optimizedContent, optimizeMode
        case isFavorite, usageCount, createdAt, updatedAt, lastUsedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        originalContent = try container.decode(String.self, forKey: .originalContent)
        optimizedContent = try container.decode(String.self, forKey: .optimizedContent)
        optimizeMode = try container.decode(OptimizeMode.self, forKey: .optimizeMode)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        usageCount = try container.decode(Int.self, forKey: .usageCount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        category = nil
        tags = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(originalContent, forKey: .originalContent)
        try container.encode(optimizedContent, forKey: .optimizedContent)
        try container.encode(optimizeMode, forKey: .optimizeMode)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(usageCount, forKey: .usageCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
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
    // 保持原有 rawValue 以兼容已存储的数据
    case concise = "简洁版"
    case detailed = "详细版"
    case professional = "专业版"

    /// 本地化键名（用于视图层本地化）
    var localizationKey: String {
        switch self {
        case .concise: return "optimize.mode.concise"
        case .detailed: return "optimize.mode.detailed"
        case .professional: return "optimize.mode.professional"
        }
    }

    /// 本地化显示名称（必须在主线程调用）
    @MainActor
    var localizedName: String {
        return LocalizationService.shared.l(localizationKey)
    }

    /// UserDefaults 存储键
    var customPromptKey: String {
        return "customSystemPrompt_\(self.rawValue)"
    }

    /// 默认系统提示词
    var defaultSystemPrompt: String {
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

    /// 获取系统提示词（优先使用自定义，否则使用默认）
    var systemPrompt: String {
        if let custom = UserDefaults.standard.string(forKey: customPromptKey), !custom.isEmpty {
            return custom
        }
        return defaultSystemPrompt
    }

    /// 保存自定义系统提示词
    static func saveCustomPrompt(_ prompt: String, for mode: OptimizeMode) {
        if prompt.isEmpty || prompt == mode.defaultSystemPrompt {
            // 如果为空或与默认相同，则删除自定义
            UserDefaults.standard.removeObject(forKey: mode.customPromptKey)
        } else {
            UserDefaults.standard.set(prompt, forKey: mode.customPromptKey)
        }
    }

    /// 获取自定义系统提示词（如果没有返回默认）
    static func getCustomPrompt(for mode: OptimizeMode) -> String {
        return UserDefaults.standard.string(forKey: mode.customPromptKey) ?? mode.defaultSystemPrompt
    }

    /// 重置为默认提示词
    static func resetToDefault(for mode: OptimizeMode) {
        UserDefaults.standard.removeObject(forKey: mode.customPromptKey)
    }
}

// 分类
@Model
final class Category: Codable {
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

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, icon, order, isSystem, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        order = try container.decode(Int.self, forKey: .order)
        isSystem = try container.decode(Bool.self, forKey: .isSystem)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(order, forKey: .order)
        try container.encode(isSystem, forKey: .isSystem)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// 标签
@Model
final class Tag: Codable {
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

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, color, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
