import SwiftUI
import SwiftData

/// Tags & Categories 管理页面 ViewModel
@MainActor
@Observable
class TagsCategoriesViewModel {
    // 数据
    var categories: [Category] = []
    var tags: [Tag] = []

    // UI 状态
    var isLoading: Bool = false
    var errorMessage: String?

    // 编辑状态
    var editingCategory: Category?
    var editingTag: Tag?
    var showingAddCategory: Bool = false
    var showingAddTag: Bool = false

    // 新建表单
    var newCategoryName: String = ""
    var newCategoryIcon: String = "folder"
    var newTagName: String = ""
    var newTagColor: String = "2563EB"

    // 依赖
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    // MARK: - 数据加载

    func loadData() {
        isLoading = true
        errorMessage = nil

        do {
            categories = try storageService.fetchCategories()
            tags = try storageService.fetchTags()
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Category 操作

    func addCategory() {
        guard !newCategoryName.isEmpty else { return }

        let maxOrder = categories.map { $0.order }.max() ?? -1
        let category = Category(
            name: newCategoryName,
            icon: newCategoryIcon,
            order: maxOrder + 1,
            isSystem: false
        )

        do {
            try storageService.saveCategory(category)
            categories.append(category)
            resetCategoryForm()
            showingAddCategory = false
            ToastManager.shared.success("分类已添加")
        } catch {
            ToastManager.shared.error("添加分类失败")
        }
    }

    func updateCategory(_ category: Category, name: String, icon: String) {
        category.name = name
        category.icon = icon

        do {
            try storageService.modelContext.save()
            loadData()
            ToastManager.shared.success("分类已更新")
        } catch {
            ToastManager.shared.error("更新分类失败")
        }
    }

    func deleteCategory(_ category: Category) {
        guard !category.isSystem else {
            ToastManager.shared.warning("系统分类无法删除")
            return
        }

        do {
            try storageService.deleteCategory(category)
            categories.removeAll { $0.id == category.id }
            ToastManager.shared.success("分类已删除")
        } catch {
            ToastManager.shared.error("删除分类失败")
        }
    }

    func resetCategoryForm() {
        newCategoryName = ""
        newCategoryIcon = "folder"
    }

    // MARK: - Tag 操作

    func addTag() {
        guard !newTagName.isEmpty else { return }

        let tag = Tag(name: newTagName, color: newTagColor)

        do {
            try storageService.saveTag(tag)
            tags.append(tag)
            resetTagForm()
            showingAddTag = false
            ToastManager.shared.success("标签已添加")
        } catch {
            ToastManager.shared.error("添加标签失败")
        }
    }

    func updateTag(_ tag: Tag, name: String, color: String) {
        tag.name = name
        tag.color = color

        do {
            try storageService.modelContext.save()
            loadData()
            ToastManager.shared.success("标签已更新")
        } catch {
            ToastManager.shared.error("更新标签失败")
        }
    }

    func deleteTag(_ tag: Tag) {
        do {
            try storageService.deleteTag(tag)
            tags.removeAll { $0.id == tag.id }
            ToastManager.shared.success("标签已删除")
        } catch {
            ToastManager.shared.error("删除标签失败")
        }
    }

    func resetTagForm() {
        newTagName = ""
        newTagColor = "2563EB"
    }
}
