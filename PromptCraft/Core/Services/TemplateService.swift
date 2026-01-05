import Foundation
import Observation

// MARK: - 模板服务
/// 负责管理场景模板的加载、搜索和统计
@MainActor
@Observable
final class TemplateService {

    // MARK: - 单例
    static let shared = TemplateService()

    // MARK: - 属性
    /// 所有可用的模板
    private(set) var allTemplates: [SceneTemplate] = []

    /// 按分类分组的模板
    private(set) var templatesByCategory: [SceneCategory: [SceneTemplate]] = [:]

    /// 热门模板（按使用次数排序）
    private(set) var popularTemplates: [SceneTemplate] = []

    /// 最近使用的模板
    private(set) var recentTemplates: [SceneTemplate] = []

    /// 收藏的模板ID
    private(set) var favoriteTemplateIds: Set<String> = []

    /// 模板使用统计
    private var usageStats: [String: Int] = [:]

    // MARK: - UserDefaults Keys
    private let recentTemplatesKey = "recent_template_ids"
    private let favoriteTemplatesKey = "favorite_template_ids"
    private let usageStatsKey = "template_usage_stats"

    // MARK: - 初始化
    private init() {
        loadBuiltInTemplates()
        loadUserData()
    }

    // MARK: - 加载内置模板
    private func loadBuiltInTemplates() {
        allTemplates = BuiltInTemplates.all

        // 按分类分组
        for category in SceneCategory.allCases {
            templatesByCategory[category] = BuiltInTemplates.templates(for: category)
        }

        // 更新热门模板
        updatePopularTemplates()
    }

    // MARK: - 加载用户数据
    private func loadUserData() {
        // 加载最近使用
        if let recentIds = UserDefaults.standard.array(forKey: recentTemplatesKey) as? [String] {
            recentTemplates = recentIds.compactMap { id in
                allTemplates.first { $0.id == id }
            }
        }

        // 加载收藏
        if let favoriteIds = UserDefaults.standard.array(forKey: favoriteTemplatesKey) as? [String] {
            favoriteTemplateIds = Set(favoriteIds)
        }

        // 加载使用统计
        if let stats = UserDefaults.standard.dictionary(forKey: usageStatsKey) as? [String: Int] {
            usageStats = stats
        }
    }

    // MARK: - 保存用户数据
    private func saveUserData() {
        // 保存最近使用
        let recentIds = recentTemplates.map { $0.id }
        UserDefaults.standard.set(recentIds, forKey: recentTemplatesKey)

        // 保存收藏
        UserDefaults.standard.set(Array(favoriteTemplateIds), forKey: favoriteTemplatesKey)

        // 保存使用统计
        UserDefaults.standard.set(usageStats, forKey: usageStatsKey)
    }

    // MARK: - 公开方法

    /// 获取指定分类的模板
    func templates(for category: SceneCategory) -> [SceneTemplate] {
        return templatesByCategory[category] ?? []
    }

    /// 根据ID获取模板
    func template(byId id: String) -> SceneTemplate? {
        return allTemplates.first { $0.id == id }
    }

    /// 搜索模板
    func search(keyword: String) -> [SceneTemplate] {
        guard !keyword.isEmpty else { return allTemplates }

        let lowercasedKeyword = keyword.lowercased()
        return allTemplates.filter { template in
            template.name.lowercased().contains(lowercasedKeyword) ||
            template.description.lowercased().contains(lowercasedKeyword) ||
            template.tags.contains { $0.lowercased().contains(lowercasedKeyword) }
        }
    }

    /// 记录模板使用
    func recordUsage(templateId: String) {
        // 更新使用统计
        usageStats[templateId, default: 0] += 1

        // 更新最近使用
        if let template = template(byId: templateId) {
            recentTemplates.removeAll { $0.id == templateId }
            recentTemplates.insert(template, at: 0)

            // 只保留最近10个
            if recentTemplates.count > 10 {
                recentTemplates = Array(recentTemplates.prefix(10))
            }
        }

        // 更新热门模板
        updatePopularTemplates()

        // 保存
        saveUserData()
    }

    /// 切换收藏状态
    func toggleFavorite(templateId: String) {
        if favoriteTemplateIds.contains(templateId) {
            favoriteTemplateIds.remove(templateId)
        } else {
            favoriteTemplateIds.insert(templateId)
        }
        saveUserData()
    }

    /// 检查是否已收藏
    func isFavorite(templateId: String) -> Bool {
        return favoriteTemplateIds.contains(templateId)
    }

    /// 获取收藏的模板
    func favoriteTemplates() -> [SceneTemplate] {
        return allTemplates.filter { favoriteTemplateIds.contains($0.id) }
    }

    /// 获取模板使用次数
    func usageCount(for templateId: String) -> Int {
        return usageStats[templateId] ?? 0
    }

    // MARK: - 私有方法

    /// 更新热门模板列表
    private func updatePopularTemplates() {
        popularTemplates = allTemplates
            .sorted { usageStats[$0.id, default: 0] > usageStats[$1.id, default: 0] }
            .prefix(10)
            .map { $0 }
    }
}

// MARK: - 模板生成服务
/// 负责根据模板生成最终内容
@MainActor
final class TemplateGenerationService {

    private let aiService: AIServiceProtocol
    private let templateService: TemplateService

    init(aiService: AIServiceProtocol, templateService: TemplateService = .shared) {
        self.aiService = aiService
        self.templateService = templateService
    }

    /// 根据模板和用户输入生成内容（非流式）
    func generate(template: SceneTemplate, fieldValues: [String: String]) async throws -> String {
        // 验证必填字段
        let missingFields = template.validateFields(fieldValues)
        guard missingFields.isEmpty else {
            let fieldNames = missingFields.map { $0.label }.joined(separator: "、")
            throw TemplateError.missingRequiredFields(fieldNames)
        }

        // 生成用户提示词
        let userPrompt = template.generatePrompt(with: fieldValues)

        // 创建临时的 OptimizeMode 用于调用 AI 服务
        // 这里我们直接使用模板的 systemPrompt
        let result = try await generateWithCustomPrompt(
            systemPrompt: template.systemPrompt,
            userPrompt: userPrompt
        )

        // 记录使用
        templateService.recordUsage(templateId: template.id)

        return result
    }

    /// 根据模板和用户输入生成内容（流式）
    func generateStream(template: SceneTemplate, fieldValues: [String: String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // 验证必填字段
                    let missingFields = template.validateFields(fieldValues)
                    guard missingFields.isEmpty else {
                        let fieldNames = missingFields.map { $0.label }.joined(separator: "、")
                        throw TemplateError.missingRequiredFields(fieldNames)
                    }

                    // 生成用户提示词
                    let userPrompt = template.generatePrompt(with: fieldValues)

                    // 使用流式生成
                    for try await chunk in generateStreamWithCustomPrompt(
                        systemPrompt: template.systemPrompt,
                        userPrompt: userPrompt
                    ) {
                        continuation.yield(chunk)
                    }

                    // 记录使用
                    await MainActor.run {
                        templateService.recordUsage(templateId: template.id)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - 私有方法

    /// 使用自定义 prompt 调用 AI（非流式）
    private func generateWithCustomPrompt(systemPrompt: String, userPrompt: String) async throws -> String {
        // 由于 AIServiceProtocol 使用 OptimizeMode，我们需要一种方式传递自定义 prompt
        // 这里暂时使用 professional 模式，实际项目中可能需要扩展 AIServiceProtocol
        // 或者直接实现一个新的方法

        // 临时解决方案：直接组合 prompt 后调用
        let combinedPrompt = """
        【系统指令】
        \(systemPrompt)

        【用户请求】
        \(userPrompt)
        """

        return try await aiService.optimize(prompt: combinedPrompt, mode: .professional)
    }

    /// 使用自定义 prompt 调用 AI（流式）
    private func generateStreamWithCustomPrompt(systemPrompt: String, userPrompt: String) -> AsyncThrowingStream<String, Error> {
        let combinedPrompt = """
        【系统指令】
        \(systemPrompt)

        【用户请求】
        \(userPrompt)
        """

        return aiService.optimizeStream(prompt: combinedPrompt, mode: .professional)
    }
}

// MARK: - 模板错误
enum TemplateError: LocalizedError {
    case missingRequiredFields(String)
    case templateNotFound(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields(let fields):
            return "请填写必填项：\(fields)"
        case .templateNotFound(let id):
            return "模板不存在：\(id)"
        case .generationFailed(let reason):
            return "生成失败：\(reason)"
        }
    }
}
