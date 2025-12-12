import SwiftUI
import SwiftData

/// Favorites 收藏页面 ViewModel
@MainActor
@Observable
class FavoritesViewModel {
    // 数据
    var favoritePrompts: [Prompt] = []

    // UI 状态
    var isLoading: Bool = false
    var errorMessage: String?
    var searchText: String = ""

    // 依赖
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    // MARK: - 计算属性

    var filteredPrompts: [Prompt] {
        guard !searchText.isEmpty else { return favoritePrompts }
        return favoritePrompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.optimizedContent.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - 数据操作

    func loadData() {
        isLoading = true
        errorMessage = nil

        do {
            let allPrompts = try storageService.fetchPrompts()
            favoritePrompts = allPrompts.filter { $0.isFavorite }
        } catch {
            errorMessage = "加载收藏失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func toggleFavorite(_ prompt: Prompt) {
        prompt.isFavorite.toggle()
        prompt.updatedAt = Date()

        do {
            try storageService.modelContext.save()
            if !prompt.isFavorite {
                favoritePrompts.removeAll { $0.id == prompt.id }
                ToastManager.shared.info("已取消收藏")
            }
        } catch {
            prompt.isFavorite.toggle() // 回滚
            ToastManager.shared.error("操作失败")
        }
    }

    func deletePrompt(_ prompt: Prompt) {
        do {
            try storageService.deletePrompt(prompt)
            favoritePrompts.removeAll { $0.id == prompt.id }
            ToastManager.shared.success("提示词已删除")
        } catch {
            ToastManager.shared.error("删除失败")
        }
    }
}
