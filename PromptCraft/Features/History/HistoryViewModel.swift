import Foundation
import SwiftData
import Observation

/// ViewModel for managing the user's prompt history.
@MainActor
@Observable
class HistoryViewModel {
    // MARK: - Published Properties for UI
    var searchText: String = ""
    var prompts: [Prompt] = []
    var selectedDateFilter: DateFilter = .all
    var selectedModeFilter: OptimizeMode? = nil

    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Computed Properties

    var filteredPrompts: [Prompt] {
        var filtered = prompts

        // 搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.originalContent.localizedCaseInsensitiveContains(searchText) ||
                $0.optimizedContent.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 日期过滤
        let now = Date()
        switch selectedDateFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            filtered = filtered.filter { $0.createdAt >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            filtered = filtered.filter { $0.createdAt >= monthAgo }
        }

        // 模式过滤
        if let mode = selectedModeFilter {
            filtered = filtered.filter { $0.optimizeMode == mode }
        }

        return filtered
    }

    /// 按日期分组的提示词
    var groupedPrompts: [(String, [Prompt])] {
        let grouped = Dictionary(grouping: filteredPrompts) { prompt -> String in
            let formatter = DateFormatter()
            if Calendar.current.isDateInToday(prompt.createdAt) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(prompt.createdAt) {
                return "Yesterday"
            } else {
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: prompt.createdAt)
            }
        }

        // 按日期排序（最新的在前）
        return grouped.sorted { first, second in
            if first.key == "Today" { return true }
            if second.key == "Today" { return false }
            if first.key == "Yesterday" { return true }
            if second.key == "Yesterday" { return false }
            return (first.value.first?.createdAt ?? Date()) > (second.value.first?.createdAt ?? Date())
        }
    }

    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Initialization
    init(storageService: StorageService) {
        self.storageService = storageService
    }

    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        errorMessage = nil

        do {
            prompts = try storageService.fetchPrompts(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        } catch {
            errorMessage = "加载历史记录失败: \(error.localizedDescription)"
            print("Error loading history: \(error)")
        }

        isLoading = false
    }

    // MARK: - CRUD Operations

    func deletePrompt(_ prompt: Prompt) {
        do {
            try storageService.deletePrompt(prompt)
            prompts.removeAll { $0.id == prompt.id }
            ToastManager.shared.success("已删除")
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
            ToastManager.shared.error("删除失败")
        }
    }

    func deleteAllHistory() {
        do {
            for prompt in prompts {
                try storageService.deletePrompt(prompt)
            }
            prompts.removeAll()
            ToastManager.shared.success("历史记录已清空")
        } catch {
            errorMessage = "清空失败: \(error.localizedDescription)"
            ToastManager.shared.error("清空失败")
        }
    }

    func toggleFavorite(_ prompt: Prompt) {
        prompt.isFavorite.toggle()
        prompt.updatedAt = Date()

        do {
            try storageService.modelContext.save()
            ToastManager.shared.success(prompt.isFavorite ? "已添加到收藏" : "已取消收藏")
        } catch {
            prompt.isFavorite.toggle() // 回滚
            ToastManager.shared.error("操作失败")
        }
    }

    func clearFilters() {
        searchText = ""
        selectedDateFilter = .all
        selectedModeFilter = nil
    }
}

// MARK: - Date Filter Enum

enum DateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    var id: String { rawValue }
}
