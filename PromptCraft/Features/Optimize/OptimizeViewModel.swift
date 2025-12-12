import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class OptimizeViewModel {
    // Input
    var inputText: String = ""
    var selectedMode: OptimizeMode = .concise

    // Output
    var outputText: String = ""
    var generatedTitle: String = ""  // AI 生成的标题
    var isGeneratingTitle: Bool = false  // 标题生成中状态
    var isLoading: Bool = false
    var errorMessage: String?
    var didSavePrompt: Bool = false

    // Statistics
    var totalOptimizations: Int = 0
    var savedTemplates: Int = 0
    var successRate: Double = 0.0
    var recentPrompts: [Prompt] = []

    // Dependencies - 使用闭包获取最新的 aiService
    private let getAIService: () -> AIServiceProtocol
    private let storageService: StorageService

    // 内部统计
    private var successCount: Int = 0
    private var failureCount: Int = 0

    init(aiServiceProvider: @escaping () -> AIServiceProtocol, storageService: StorageService) {
        self.getAIService = aiServiceProvider
        self.storageService = storageService
        loadStatistics()
    }

    // 便捷初始化方法（兼容旧代码）
    convenience init(aiService: AIServiceProtocol, storageService: StorageService) {
        self.init(aiServiceProvider: { aiService }, storageService: storageService)
    }

    // MARK: - 统计数据加载

    func loadStatistics() {
        // 从 UserDefaults 加载统计
        let defaults = UserDefaults.standard
        totalOptimizations = defaults.integer(forKey: "stats_totalOptimizations")
        successCount = defaults.integer(forKey: "stats_successCount")
        failureCount = defaults.integer(forKey: "stats_failureCount")

        // 计算成功率
        let total = successCount + failureCount
        successRate = total > 0 ? Double(successCount) / Double(total) * 100 : 0

        // 加载保存的模板数量和最近提示词
        do {
            let allPrompts = try storageService.fetchPrompts()
            savedTemplates = allPrompts.count
            recentPrompts = Array(allPrompts.prefix(5))
        } catch {
            print("Failed to load statistics: \(error)")
        }
    }

    private func saveStatistics() {
        let defaults = UserDefaults.standard
        defaults.set(totalOptimizations, forKey: "stats_totalOptimizations")
        defaults.set(successCount, forKey: "stats_successCount")
        defaults.set(failureCount, forKey: "stats_failureCount")
    }

    // MARK: - 优化操作

    @MainActor
    func optimize() async {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter a prompt to optimize."
            return
        }

        isLoading = true
        errorMessage = nil
        outputText = ""
        generatedTitle = ""  // 清空之前的标题
        didSavePrompt = false

        defer {
            isLoading = false
        }

        do {
            let currentAIService = getAIService()
            for try await chunk in currentAIService.optimizeStream(prompt: inputText, mode: selectedMode) {
                outputText += chunk
            }

            // 优化成功，更新统计
            totalOptimizations += 1
            successCount += 1
            successRate = Double(successCount) / Double(successCount + failureCount) * 100
            saveStatistics()

            // 优化成功后，异步生成标题（不阻塞用户操作）
            Task {
                await generateTitleForOutput()
            }

        } catch {
            errorMessage = error.localizedDescription

            // 优化失败，更新统计
            failureCount += 1
            successRate = Double(successCount) / Double(successCount + failureCount) * 100
            saveStatistics()
        }
    }

    /// 为优化后的内容生成标题
    @MainActor
    private func generateTitleForOutput() async {
        guard !outputText.isEmpty else { return }

        isGeneratingTitle = true
        defer { isGeneratingTitle = false }

        do {
            let currentAIService = getAIService()
            generatedTitle = try await currentAIService.generateTitle(for: outputText)
        } catch {
            // 标题生成失败时，使用回退方案：截取优化内容的前30个字符
            print("⚠️ [OptimizeViewModel] Failed to generate title: \(error)")
            generatedTitle = generateFallbackTitle(from: outputText)
        }
    }

    /// 回退标题生成：从内容中提取
    private func generateFallbackTitle(from content: String) -> String {
        // 去除换行符，取第一行或前30个字符
        let firstLine = content.split(separator: "\n").first.map(String.init) ?? content
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 30 {
            return trimmed
        }
        return String(trimmed.prefix(30)) + "..."
    }

    /// 重新优化当前输出
    @MainActor
    func reoptimize() async {
        guard !outputText.isEmpty else { return }

        // 将当前输出作为新输入
        inputText = outputText
        await optimize()
    }

    /// 清空当前内容
    func clearAll() {
        inputText = ""
        outputText = ""
        generatedTitle = ""
        errorMessage = nil
        didSavePrompt = false
    }

    /// 交换输入输出
    func swapInputOutput() {
        guard !outputText.isEmpty else { return }
        let temp = inputText
        inputText = outputText
        outputText = temp
        // 交换后标题可能不再适用，清空让用户重新生成
        generatedTitle = ""
    }

    // MARK: - 保存操作

    func savePrompt() {
        guard !inputText.isEmpty, !outputText.isEmpty else { return }

        // 优先使用 AI 生成的标题，如果没有则使用回退方案
        let title = generatedTitle.isEmpty ? generateFallbackTitle(from: outputText) : generatedTitle

        let prompt = Prompt(
            title: title,
            originalContent: inputText,
            optimizedContent: outputText,
            optimizeMode: selectedMode
        )

        do {
            try storageService.savePrompt(prompt)
            didSavePrompt = true
            savedTemplates += 1
            recentPrompts.insert(prompt, at: 0)
            if recentPrompts.count > 5 {
                recentPrompts.removeLast()
            }
            print("Prompt saved successfully!")
        } catch {
            print("Error saving prompt: \(error)")
            errorMessage = "Failed to save prompt: \(error.localizedDescription)"
        }
    }

    // MARK: - 使用已保存的提示词

    func usePrompt(_ prompt: Prompt) {
        inputText = prompt.originalContent
        outputText = prompt.optimizedContent
        selectedMode = prompt.optimizeMode

        // 更新使用次数
        prompt.incrementUsage()
        do {
            try storageService.modelContext.save()
        } catch {
            print("Failed to update usage count: \(error)")
        }
    }
}
