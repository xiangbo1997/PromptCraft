import SwiftData
import Foundation

// Custom error type for storage-related operations
enum StorageError: LocalizedError {
    case cannotDeleteSystemCategory
    case dataCorrupted
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteSystemCategory:
            return "Cannot delete a system-provided category."
        case .dataCorrupted:
            return "The data file is corrupted."
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        }
    }
}

// Service class responsible for all SwiftData operations
@MainActor
class StorageService {
    let modelContext: ModelContext // 改为公开访问以支持直接保存

    // Convenience initializer using the shared model container from the app
    init() {
        self.modelContext = PromptCraftApp.sharedModelContainer.mainContext
    }

    // 允许注入自定义 ModelContext（用于测试）
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Prompt CRUD
    
    func savePrompt(_ prompt: Prompt) throws {
        modelContext.insert(prompt)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchPrompts(sortBy sortDescriptors: [SortDescriptor<Prompt>] = [SortDescriptor(\.updatedAt, order: .reverse)]) throws -> [Prompt] {
        let descriptor = FetchDescriptor<Prompt>(sortBy: sortDescriptors)
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StorageError.fetchFailed(error)
        }
    }
    
    func fetchPrompts(category: Category) throws -> [Prompt] {
        let categoryID = category.id
        let predicate = #Predicate<Prompt> { prompt in
            prompt.category?.id == categoryID
        }
        let descriptor = FetchDescriptor<Prompt>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StorageError.fetchFailed(error)
        }
    }
    
    func searchPrompts(query: String) throws -> [Prompt] {
        let predicate = #Predicate<Prompt> { prompt in
            prompt.title.localizedStandardContains(query) ||
            prompt.optimizedContent.localizedStandardContains(query) ||
            prompt.originalContent.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Prompt>(predicate: predicate)
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StorageError.fetchFailed(error)
        }
    }
    
    func deletePrompt(_ prompt: Prompt) throws {
        modelContext.delete(prompt)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.deleteFailed(error)
        }
    }
    
    func updatePrompt(_ prompt: Prompt) throws {
        // The prompt object is already in the context, just need to save.
        // The calling function should have already modified the prompt's properties.
        prompt.updatedAt = Date()
        do {
            try modelContext.save()
        } catch {
            throw StorageError.saveFailed(error)
        }
    }
    
    // MARK: - Category CRUD
    
    func saveCategory(_ category: Category) throws {
        modelContext.insert(category)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.order)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StorageError.fetchFailed(error)
        }
    }
    
    func deleteCategory(_ category: Category) throws {
        guard !category.isSystem else {
            throw StorageError.cannotDeleteSystemCategory
        }
        modelContext.delete(category)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.deleteFailed(error)
        }
    }
    
    // MARK: - Tag CRUD
    
    func saveTag(_ tag: Tag) throws {
        modelContext.insert(tag)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StorageError.fetchFailed(error)
        }
    }
    
    func deleteTag(_ tag: Tag) throws {
        modelContext.delete(tag)
        do {
            try modelContext.save()
        } catch {
            throw StorageError.deleteFailed(error)
        }
    }

    // MARK: - Initial Data

    /// Sets up default categories if none exist.
    func setupDefaultCategoriesIfNeeded() {
        do {
            let categories = try fetchCategories()
            guard categories.isEmpty else { return }
            
            let defaultCategories = [
                Category(name: "General", icon: "star.fill", order: 0, isSystem: true),
                Category(name: "Writing", icon: "pencil", order: 1, isSystem: true),
                Category(name: "Programming", icon: "chevron.left.forwardslash.chevron.right", order: 2, isSystem: true),
                Category(name: "Translation", icon: "globe", order: 3, isSystem: true),
                Category(name: "Marketing", icon: "megaphone.fill", order: 4, isSystem: true),
                Category(name: "Education", icon: "book.fill", order: 5, isSystem: true),
                Category(name: "Business", icon: "briefcase.fill", order: 6, isSystem: true)
            ]
            
            for category in defaultCategories {
                try saveCategory(category)
            }
            print("[StorageService] Default categories created.")
        } catch {
            print("[StorageService] Error setting up default categories: \(error.localizedDescription)")
        }
    }
}

// MARK: - Data Import/Export

// A struct to represent the data to be exported.
struct ExportData: Codable {
    let prompts: [Prompt]
    let categories: [Category]
    let tags: [Tag]
    let exportDate: Date
    let appVersion: String
}

extension StorageService {
    func exportData() throws -> Data {
        let prompts = try fetchPrompts()
        let categories = try fetchCategories()
        let tags = try fetchTags()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let exportData = ExportData(
            prompts: prompts,
            categories: categories,
            tags: tags,
            exportDate: Date(),
            appVersion: appVersion
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(exportData)
    }
    
    func importData(_ data: Data) throws {
        let decoder = JSONDecoder()
        let importData = try decoder.decode(ExportData.self, from: data)
        
        // Basic merge logic: Add items if they don't exist.
        // A more robust implementation might handle conflicts.
        
        let existingCategories = try fetchCategories()
        for category in importData.categories {
            if !existingCategories.contains(where: { $0.id == category.id }) {
                try saveCategory(category)
            }
        }
        
        let existingTags = try fetchTags()
        for tag in importData.tags {
            if !existingTags.contains(where: { $0.id == tag.id }) {
                try saveTag(tag)
            }
        }
        
        let existingPrompts = try fetchPrompts()
        for prompt in importData.prompts {
            if !existingPrompts.contains(where: { $0.id == prompt.id }) {
                try savePrompt(prompt)
            }
        }
    }
}
