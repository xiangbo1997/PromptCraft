import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    @State private var viewModel: LibraryViewModel

    // State for showing export/import dialogs
    @State private var showingFileExporter: Bool = false
    @State private var showingFileImporter: Bool = false
    @State private var showingBatchExporter: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var exportedFileURL: URL? = nil

    // State for editing prompt
    @State private var editingPrompt: Prompt? = nil

    init(storageService: StorageService) {
        _viewModel = State(initialValue: LibraryViewModel(storageService: storageService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Toolbar / Search & Filters
            HStack(spacing: Spacing.md) {
                // 批量选择模式按钮
                Button(action: { viewModel.toggleSelectionMode() }) {
                    Label(
                        viewModel.isSelectionMode ? "Done" : "Select",
                        systemImage: viewModel.isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(viewModel.isSelectionMode ? Color.primaryApp.opacity(0.1) : Color.surface)
                .foregroundStyle(viewModel.isSelectionMode ? Color.primaryApp : Color.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(viewModel.isSelectionMode ? Color.primaryApp : Color.border, lineWidth: 1))

                // Search Field
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                        .font(.system(size: 14))

                    TextField("Search Prompts...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.border, lineWidth: 1)
                )

                // Category Picker
                Picker("Category", selection: $viewModel.selectedCategory) {
                    Text("All Categories").tag(nil as Category?)
                    ForEach(viewModel.availableCategories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)

                // Tags Filter
                Menu {
                    ForEach(viewModel.availableTags) { tag in
                        Toggle(isOn: Binding(get: { viewModel.selectedTags.contains(tag) }, set: { isSelected in
                            if isSelected {
                                viewModel.selectedTags.insert(tag)
                            } else {
                                viewModel.selectedTags.remove(tag)
                            }
                        })) {
                            Label(tag.name, systemImage: viewModel.selectedTags.contains(tag) ? "checkmark.tag.fill" : "tag")
                        }
                    }
                    if !viewModel.selectedTags.isEmpty {
                        Button("Clear Tags") { viewModel.selectedTags.removeAll() }
                    }
                } label: {
                    Label("Tags (\(viewModel.selectedTags.count))", systemImage: "tag")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewModel.selectedTags.isEmpty ? Color.surface : Color.primaryApp.opacity(0.1))
                        .foregroundStyle(viewModel.selectedTags.isEmpty ? Color.textPrimary : Color.primaryApp)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border, lineWidth: 1))
                }
                .menuStyle(.borderlessButton)

                // Sort Picker
                Picker("Sort By", selection: $viewModel.sortOption) {
                    ForEach(LibraryViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)

                // Add Prompt Button
                Button(action: { }) {
                    Label("New Prompt", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primaryApp)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(Spacing.lg)
            .background(Color.backgroundApp)

            // MARK: - 批量操作栏（选择模式下显示）
            if viewModel.isSelectionMode {
                batchActionsBar
            }

            Divider()

            // MARK: - Content Area
            if viewModel.isLoading {
                ProgressView("Loading Prompts...")
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.errorMessage != nil {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.error)
                    Text("Error: \(viewModel.errorMessage ?? "Unknown error")")
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredPrompts.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.textTertiary)
                    Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil && viewModel.selectedTags.isEmpty ? "No prompts saved yet." : "No matching prompts found.")
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textSecondary)

                    if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil || !viewModel.selectedTags.isEmpty {
                        Button("Clear Filters") {
                            viewModel.searchText = ""
                            viewModel.selectedCategory = nil
                            viewModel.selectedTags.removeAll()
                        }
                        .buttonStyle(.link)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.filteredPrompts) { prompt in
                            PromptCard(
                                prompt: prompt,
                                isSelectionMode: viewModel.isSelectionMode,
                                isSelected: viewModel.isSelected(prompt),
                                onSelect: { viewModel.toggleSelection(for: prompt) },
                                onEdit: { editingPrompt = prompt },
                                onDelete: { viewModel.deletePrompt(prompt) },
                                onToggleFavorite: { viewModel.toggleFavorite(prompt: prompt) },
                                onCopy: {
                                    appState.clipboardService.copy(prompt.optimizedContent)
                                    ToastManager.shared.success(localization.l("toast.copied"))
                                },
                                availableCategories: viewModel.availableCategories,
                                availableTags: viewModel.availableTags
                            )
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .background(Color.backgroundApp)
        .onAppear(perform: viewModel.loadData)
        .fileExporter(
            isPresented: $showingFileExporter,
            document: ExportableData(data: (try? appState.storageService.exportData()) ?? Data()),
            contentType: UTType.json,
            defaultFilename: "promptcraft_export_\(Date().formatted(.iso8601)).json"
        ) { result in
            switch result {
            case .success(let url):
                self.exportedFileURL = url
                ToastManager.shared.success(localization.l("toast.saved"))
            case .failure(let error):
                ToastManager.shared.error("\(localization.l("common.error")): \(error.localizedDescription)")
            }
        }
        .fileExporter(
            isPresented: $showingBatchExporter,
            document: ExportableData(data: viewModel.exportSelectedPrompts() ?? Data()),
            contentType: UTType.json,
            defaultFilename: "promptcraft_selected_\(Date().formatted(.iso8601)).json"
        ) { result in
            switch result {
            case .success(let url):
                self.exportedFileURL = url
                ToastManager.shared.success(localization.l("toast.saved"))
                viewModel.selectedPromptIDs.removeAll()
            case .failure(let error):
                ToastManager.shared.error("\(localization.l("common.error")): \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedFileURL = urls.first else { return }
                do {
                    let data = try Data(contentsOf: selectedFileURL)
                    try appState.storageService.importData(data)
                    viewModel.loadData()
                    ToastManager.shared.success(localization.l("common.success"))
                } catch {
                    ToastManager.shared.error("\(localization.l("common.error")): \(error.localizedDescription)")
                    viewModel.errorMessage = "Failed to import data: \(error.localizedDescription)"
                }
            case .failure(let error):
                ToastManager.shared.error("\(localization.l("common.error")): \(error.localizedDescription)")
            }
        }
        .alert("Delete Selected Prompts?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(viewModel.selectedCount) Items", role: .destructive) {
                viewModel.deleteSelectedPrompts()
            }
        } message: {
            Text("This will permanently delete \(viewModel.selectedCount) selected prompts. This action cannot be undone.")
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditSheet(
                prompt: prompt,
                availableCategories: viewModel.availableCategories,
                availableTags: viewModel.availableTags,
                onSave: {
                    viewModel.loadData()
                    ToastManager.shared.success(localization.l("toast.saved"))
                }
            )
        }
    }

    // MARK: - 批量操作栏
    private var batchActionsBar: some View {
        HStack(spacing: Spacing.md) {
            // 全选/取消全选
            Button(action: { viewModel.toggleSelectAll() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isAllSelected ? "checkmark.square.fill" : "square")
                    Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                }
                .font(.bodySmall)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primaryApp)

            Divider()
                .frame(height: 20)

            // 选中数量
            Text("\(viewModel.selectedCount) selected")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            // 批量操作按钮
            if viewModel.selectedCount > 0 {
                // 批量收藏
                Menu {
                    Button(action: { viewModel.favoriteSelectedPrompts() }) {
                        Label("Add to Favorites", systemImage: "star.fill")
                    }
                    Button(action: { viewModel.unfavoriteSelectedPrompts() }) {
                        Label("Remove from Favorites", systemImage: "star.slash")
                    }
                } label: {
                    Label("Favorite", systemImage: "star")
                        .font(.bodySmall)
                }
                .menuStyle(.borderlessButton)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border, lineWidth: 1))

                // 批量导出
                Button(action: { showingBatchExporter = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.bodySmall)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border, lineWidth: 1))

                // 批量删除
                Button(action: { showingDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                        .font(.bodySmall)
                        .foregroundStyle(Color.error)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.errorBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.infoBackground.opacity(0.5))
    }
}

// MARK: - PromptCard View
struct PromptCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let prompt: Prompt
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onCopy: () -> Void
    var availableCategories: [Category] = []
    var availableTags: [Tag] = []

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // 选择模式下显示复选框
            if isSelectionMode {
                Button(action: { onSelect?() }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Color.primaryApp : Color.textTertiary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // 可编辑标题
                        EditableTitle(title: prompt.title) { newTitle in
                            prompt.title = newTitle
                            prompt.updatedAt = Date()
                            try? modelContext.save()
                        }

                        // 分类和标签行
                        HStack(spacing: Spacing.sm) {
                            // 分类
                            if let category = prompt.category {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 10))
                                    Text(category.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.infoBackground)
                                .foregroundStyle(Color.primaryApp)
                                .clipShape(Capsule())
                            }

                            // 标签
                            ForEach(prompt.tags.prefix(3)) { tag in
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color(nsColor: NSColor(hex: tag.color)))
                                        .frame(width: 6, height: 6)
                                    Text(tag.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(nsColor: NSColor(hex: tag.color)).opacity(0.1))
                                .foregroundStyle(Color.textSecondary)
                                .clipShape(Capsule())
                            }

                            // 如果标签超过3个，显示更多
                            if prompt.tags.count > 3 {
                                Text("+\(prompt.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }

                            // 时间
                            Text(prompt.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }

                    Spacer()

                    if !isSelectionMode {
                        HStack(spacing: Spacing.sm) {
                            // 优化模式标签
                            Text(prompt.optimizeMode.rawValue)
                                .font(.caption)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(Color.infoBackground)
                                .foregroundStyle(Color.primaryApp)
                                .clipShape(Capsule())

                            // 收藏按钮
                            Button(action: onToggleFavorite) {
                                Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 14))
                                    .foregroundStyle(prompt.isFavorite ? Color.yellow : Color.textSecondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.backgroundApp.opacity(isHovering ? 1 : 0))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help(prompt.isFavorite ? "Remove from Favorites" : "Add to Favorites")

                            // 复制按钮
                            Button(action: onCopy) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.backgroundApp.opacity(isHovering ? 1 : 0))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help("Copy to Clipboard")

                            // 编辑按钮
                            Button(action: onEdit) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.backgroundApp.opacity(isHovering ? 1 : 0))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help("Edit Prompt")

                            // 删除按钮
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.error.opacity(0.8))
                                    .frame(width: 28, height: 28)
                                    .background(Color.errorBackground.opacity(isHovering ? 0.5 : 0))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help("Delete Prompt")
                        }
                        .opacity(isHovering ? 1 : 0.6)
                    }
                }

                Text(prompt.optimizedContent)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(Spacing.md)
        .background(isSelected ? Color.primaryApp.opacity(0.05) : Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isSelected ? Color.primaryApp : (isHovering ? Color.primaryApp.opacity(0.3) : Color.border), lineWidth: isSelected ? 2 : 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if isSelectionMode {
                onSelect?()
            }
        }
    }
}

// MARK: - PromptEditSheet
/// 提示词编辑弹窗 - 用于编辑分类和标签
struct PromptEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let prompt: Prompt
    let availableCategories: [Category]
    let availableTags: [Tag]
    var onSave: (() -> Void)? = nil

    @State private var selectedCategory: Category?
    @State private var selectedTagIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("编辑提示词")
                    .font(.h3)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.backgroundApp)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .background(Color.surface)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 标题预览
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("标题")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        Text(prompt.title)
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                    }

                    // 分类选择
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("分类")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: Spacing.sm) {
                            // 无分类选项
                            CategorySelectButton(
                                name: "无分类",
                                icon: "folder",
                                isSelected: selectedCategory == nil,
                                onTap: { selectedCategory = nil }
                            )

                            ForEach(availableCategories) { category in
                                CategorySelectButton(
                                    name: category.name,
                                    icon: category.icon,
                                    isSelected: selectedCategory?.id == category.id,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                    }

                    // 标签选择
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("标签")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)

                            Spacer()

                            if !selectedTagIDs.isEmpty {
                                Button("清除全部") {
                                    selectedTagIDs.removeAll()
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.primaryApp)
                            }
                        }

                        if availableTags.isEmpty {
                            Text("暂无标签，请先在「标签与分类」页面创建")
                                .font(.bodySmall)
                                .foregroundStyle(Color.textTertiary)
                                .padding(.vertical, Spacing.md)
                        } else {
                            FlowLayout(spacing: Spacing.sm) {
                                ForEach(availableTags) { tag in
                                    TagSelectButton(
                                        tag: tag,
                                        isSelected: selectedTagIDs.contains(tag.id),
                                        onTap: {
                                            if selectedTagIDs.contains(tag.id) {
                                                selectedTagIDs.remove(tag.id)
                                            } else {
                                                selectedTagIDs.insert(tag.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // 内容预览
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("优化后内容")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        Text(prompt.optimizedContent)
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(5)
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.backgroundApp)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                }
                .padding(Spacing.lg)
            }

            Divider()

            // 操作按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.appSecondary)

                Spacer()

                Button("保存") {
                    saveChanges()
                    dismiss()
                }
                .buttonStyle(.appPrimary)
            }
            .padding(Spacing.lg)
            .background(Color.surface)
        }
        .frame(width: 500, height: 600)
        .background(Color.backgroundApp)
        .onAppear {
            selectedCategory = prompt.category
            selectedTagIDs = Set(prompt.tags.map { $0.id })
        }
    }

    private func saveChanges() {
        prompt.category = selectedCategory
        prompt.tags = availableTags.filter { selectedTagIDs.contains($0.id) }
        prompt.updatedAt = Date()

        do {
            try modelContext.save()
            onSave?()
        } catch {
            print("Error saving prompt: \(error)")
        }
    }
}

// MARK: - 分类选择按钮
struct CategorySelectButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(name)
                    .font(.bodySmall)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.primaryApp : Color.surface)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isSelected ? Color.primaryApp : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 标签选择按钮
struct TagSelectButton: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var tagColor: Color {
        Color(nsColor: NSColor(hex: tag.color))
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.bodySmall)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(isSelected ? tagColor.opacity(0.2) : Color.surface)
            .foregroundStyle(isSelected ? tagColor : Color.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? tagColor : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (自适应换行布局)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - ExportableData Document
struct ExportableData: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadUnknown)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    LibraryView(storageService: StorageService())
        .environment(AppState())
        .environment(\.modelContext, PromptCraftApp.sharedModelContainer.mainContext)
}
