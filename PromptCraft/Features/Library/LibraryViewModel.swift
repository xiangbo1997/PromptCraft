import Foundation
import SwiftData
import Observation

/// ViewModel for managing the Prompt Library, including fetching, filtering, and sorting prompts.
@MainActor
@Observable
class LibraryViewModel {
    // MARK: - Published Properties for UI
    var searchText: String = "" {
        didSet { applyFiltersAndSort() }
    }
    var selectedCategory: Category? {
        didSet { applyFiltersAndSort() }
    }
    var selectedTags: Set<Tag> = [] {
        didSet { applyFiltersAndSort() }
    }
    var sortOption: SortOption = .updatedAtDesc {
        didSet { applyFiltersAndSort() }
    }

    var prompts: [Prompt] = [] // All fetched prompts
    var filteredPrompts: [Prompt] = [] // Prompts after applying filters and sort
    var availableCategories: [Category] = []
    var availableTags: [Tag] = []

    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Initialization
    init(storageService: StorageService) {
        self.storageService = storageService
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        errorMessage = nil
        do {
            self.prompts = try storageService.fetchPrompts(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            self.availableCategories = try storageService.fetchCategories()
            self.availableTags = try storageService.fetchTags()
            applyFiltersAndSort()
        } catch {
            self.errorMessage = "Failed to load library data: \(error.localizedDescription)"
            print("Error loading library data: \(error)")
        }
        self.isLoading = false
    }
    
    // MARK: - Filtering and Sorting Logic
    private func applyFiltersAndSort() {
        var filtered = prompts
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.originalContent.localizedCaseInsensitiveContains(searchText) ||
                $0.optimizedContent.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Apply tags filter
        if !selectedTags.isEmpty {
            filtered = filtered.filter { prompt in
                // Check if any of the prompt's tags are in the selectedTags set
                !Set(prompt.tags.map { $0.id }).isDisjoint(with: Set(selectedTags.map { $0.id }))
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .updatedAtDesc:
            filtered.sort { $0.updatedAt > $1.updatedAt }
        case .updatedAtAsc:
            filtered.sort { $0.updatedAt < $1.updatedAt }
        case .createdAtDesc:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .createdAtAsc:
            filtered.sort { $0.createdAt < $1.createdAt }
        case .titleAsc:
            filtered.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .titleDesc:
            filtered.sort { $0.title.localizedStandardCompare($1.title) == .orderedDescending }
        case .usageCountDesc:
            filtered.sort { $0.usageCount > $1.usageCount }
        case .usageCountAsc:
            filtered.sort { $0.usageCount < $1.usageCount }
        case .isFavoriteDesc:
            // Favorites first, then by updated date descending
            filtered.sort { 
                if $0.isFavorite && !$1.isFavorite { return true }
                if !$0.isFavorite && $1.isFavorite { return false }
                return $0.updatedAt > $1.updatedAt
            }
        }
        
        self.filteredPrompts = filtered
    }
    
    // MARK: - CRUD Operations

    func deletePrompt(_ prompt: Prompt) {
        do {
            try storageService.deletePrompt(prompt)
            // Refresh data after deletion
            loadData()
        } catch {
            errorMessage = "Failed to delete prompt: \(error.localizedDescription)"
            print("Error deleting prompt: \(error)")
        }
    }

    func addOrUpdatePrompt(_ prompt: Prompt) {
        do {
            try storageService.savePrompt(prompt) // savePrompt also handles updates if entity exists
            loadData()
        } catch {
            errorMessage = "Failed to save prompt: \(error.localizedDescription)"
            print("Error saving prompt: \(error)")
        }
    }
    
    func toggleFavorite(prompt: Prompt) {
        prompt.isFavorite.toggle()
        addOrUpdatePrompt(prompt) // Save the change
    }

    func incrementUsage(prompt: Prompt) {
        prompt.incrementUsage()
        addOrUpdatePrompt(prompt) // Save the change
    }

    // MARK: - 批量操作相关属性

    /// 是否处于批量选择模式
    var isSelectionMode: Bool = false

    /// 当前选中的提示词 ID 集合
    var selectedPromptIDs: Set<UUID> = []

    /// 选中的提示词数量
    var selectedCount: Int {
        selectedPromptIDs.count
    }

    /// 是否全选
    var isAllSelected: Bool {
        !filteredPrompts.isEmpty && selectedPromptIDs.count == filteredPrompts.count
    }

    // MARK: - 批量操作方法

    /// 进入/退出批量选择模式
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedPromptIDs.removeAll()
        }
    }

    /// 选中/取消选中单个提示词
    func toggleSelection(for prompt: Prompt) {
        if selectedPromptIDs.contains(prompt.id) {
            selectedPromptIDs.remove(prompt.id)
        } else {
            selectedPromptIDs.insert(prompt.id)
        }
    }

    /// 检查某个提示词是否被选中
    func isSelected(_ prompt: Prompt) -> Bool {
        selectedPromptIDs.contains(prompt.id)
    }

    /// 全选/取消全选
    func toggleSelectAll() {
        if isAllSelected {
            selectedPromptIDs.removeAll()
        } else {
            selectedPromptIDs = Set(filteredPrompts.map { $0.id })
        }
    }

    /// 批量删除选中的提示词
    func deleteSelectedPrompts() {
        let promptsToDelete = prompts.filter { selectedPromptIDs.contains($0.id) }
        var deletedCount = 0

        for prompt in promptsToDelete {
            do {
                try storageService.deletePrompt(prompt)
                deletedCount += 1
            } catch {
                print("Error deleting prompt \(prompt.id): \(error)")
            }
        }

        selectedPromptIDs.removeAll()
        loadData()

        if deletedCount > 0 {
            ToastManager.shared.success("已删除 \(deletedCount) 个提示词")
        }
    }

    /// 批量添加到收藏
    func favoriteSelectedPrompts() {
        let promptsToFavorite = prompts.filter { selectedPromptIDs.contains($0.id) && !$0.isFavorite }

        for prompt in promptsToFavorite {
            prompt.isFavorite = true
            prompt.updatedAt = Date()
        }

        do {
            try storageService.modelContext.save()
            loadData()
            ToastManager.shared.success("已添加 \(promptsToFavorite.count) 个提示词到收藏")
        } catch {
            print("Error favoriting prompts: \(error)")
            ToastManager.shared.error("收藏失败")
        }
    }

    /// 批量取消收藏
    func unfavoriteSelectedPrompts() {
        let promptsToUnfavorite = prompts.filter { selectedPromptIDs.contains($0.id) && $0.isFavorite }

        for prompt in promptsToUnfavorite {
            prompt.isFavorite = false
            prompt.updatedAt = Date()
        }

        do {
            try storageService.modelContext.save()
            loadData()
            ToastManager.shared.success("已取消 \(promptsToUnfavorite.count) 个提示词的收藏")
        } catch {
            print("Error unfavoriting prompts: \(error)")
            ToastManager.shared.error("取消收藏失败")
        }
    }

    /// 获取选中提示词用于导出
    func getSelectedPromptsForExport() -> [Prompt] {
        return prompts.filter { selectedPromptIDs.contains($0.id) }
    }

    /// 导出选中的提示词为 JSON 数据
    func exportSelectedPrompts() -> Data? {
        let selectedPrompts = getSelectedPromptsForExport()
        guard !selectedPrompts.isEmpty else { return nil }

        // 创建导出数据结构
        let exportData = selectedPrompts.map { prompt -> [String: Any] in
            return [
                "id": prompt.id.uuidString,
                "title": prompt.title,
                "originalContent": prompt.originalContent,
                "optimizedContent": prompt.optimizedContent,
                "optimizeMode": prompt.optimizeMode.rawValue,
                "isFavorite": prompt.isFavorite,
                "usageCount": prompt.usageCount,
                "createdAt": ISO8601DateFormatter().string(from: prompt.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: prompt.updatedAt),
                "tags": prompt.tags.map { $0.name },
                "category": prompt.category?.name ?? ""
            ]
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Error serializing export data: \(error)")
            return nil
        }
    }

    // MARK: - Nested Types
    
    enum SortOption: String, CaseIterable, Identifiable {
        case updatedAtDesc = "Last Updated (Newest)"
        case updatedAtAsc = "Last Updated (Oldest)"
        case createdAtDesc = "Created (Newest)"
        case createdAtAsc = "Created (Oldest)"
        case titleAsc = "Title (A-Z)"
        case titleDesc = "Title (Z-A)"
        case usageCountDesc = "Usage Count (High-Low)"
        case usageCountAsc = "Usage Count (Low-High)"
        case isFavoriteDesc = "Favorites First"
        
        var id: String { rawValue }
    }
}
