import SwiftUI
import SwiftData

/// Tags & Categories 管理页面
struct TagsCategoriesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: TagsCategoriesViewModel
    @State private var selectedSegment: Int = 0 // 0: Categories, 1: Tags

    init(storageService: StorageService) {
        _viewModel = State(initialValue: TagsCategoriesViewModel(storageService: storageService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Tags & Categories")
                    .font(.h2)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                // Segment Picker
                Picker("", selection: $selectedSegment) {
                    Text("Categories").tag(0)
                    Text("Tags").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                // Add Button
                Button(action: {
                    if selectedSegment == 0 {
                        viewModel.showingAddCategory = true
                    } else {
                        viewModel.showingAddTag = true
                    }
                }) {
                    Label(selectedSegment == 0 ? "Add Category" : "Add Tag", systemImage: "plus")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primaryApp)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(Spacing.lg)
            .background(Color.backgroundApp)

            Divider()

            // MARK: - Content
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.error)
                    Text(error)
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textSecondary)
                    Button("Retry") { viewModel.loadData() }
                        .buttonStyle(.appPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    if selectedSegment == 0 {
                        categoriesContent
                    } else {
                        tagsContent
                    }
                }
            }
        }
        .background(Color.backgroundApp)
        .onAppear { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showingAddCategory) {
            AddCategorySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddTag) {
            AddTagSheet(viewModel: viewModel)
        }
    }

    // MARK: - Categories Content

    private var categoriesContent: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(viewModel.categories) { category in
                CategoryRow(
                    category: category,
                    onEdit: { viewModel.editingCategory = category },
                    onDelete: { viewModel.deleteCategory(category) }
                )
            }

            if viewModel.categories.isEmpty {
                emptyState(icon: "folder", message: "No categories yet")
            }
        }
        .padding(Spacing.lg)
    }

    // MARK: - Tags Content

    @ViewBuilder
    private var tagsContent: some View {
        if viewModel.tags.isEmpty {
            emptyState(icon: "tag", message: "No tags yet")
        } else {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(viewModel.tags) { tag in
                    TagCard(
                        tag: tag,
                        onEdit: { viewModel.editingTag = tag },
                        onDelete: { viewModel.deleteTag(tag) }
                    )
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
            Text(message)
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: category.icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryApp)
                .frame(width: 40, height: 40)
                .background(Color.infoBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(category.name)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)

                    if category.isSystem {
                        Text("System")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.backgroundApp)
                            .clipShape(Capsule())
                    }
                }

                Text("\(category.prompts?.count ?? 0) prompts")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Actions (show on hover)
            if isHovering && !category.isSystem {
                HStack(spacing: Spacing.sm) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovering ? Color.primaryApp.opacity(0.3) : Color.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Tag Card

struct TagCard: View {
    let tag: Tag
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering: Bool = false

    var tagColor: Color {
        Color(nsColor: NSColor(hex: tag.color))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(tagColor)
                    .frame(width: 12, height: 12)

                Text(tag.name)
                    .font(.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if isHovering {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                }
            }

            Text("Created \(tag.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovering ? tagColor.opacity(0.5) : Color.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Bindable var viewModel: TagsCategoriesViewModel
    @Environment(\.dismiss) private var dismiss

    // 常用图标列表
    let icons = [
        "folder", "folder.fill", "star", "star.fill", "heart", "heart.fill",
        "bookmark", "bookmark.fill", "tag", "tag.fill", "pencil", "doc",
        "doc.text", "book", "book.fill", "globe", "briefcase", "briefcase.fill",
        "megaphone", "megaphone.fill", "lightbulb", "lightbulb.fill",
        "graduationcap", "graduationcap.fill", "wrench", "wrench.fill",
        "gearshape", "gearshape.fill", "chart.bar", "chart.bar.fill"
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Add Category")
                    .font(.h3)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Name Input
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                TextField("Category name", text: $viewModel.newCategoryName)
                    .textFieldStyle(.roundedBorder)
            }

            // Icon Selection
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Icon")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: Spacing.sm) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { viewModel.newCategoryIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .background(viewModel.newCategoryIcon == icon ? Color.primaryApp : Color.surface)
                                .foregroundStyle(viewModel.newCategoryIcon == icon ? .white : Color.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            // Actions
            HStack {
                Button("Cancel") {
                    viewModel.resetCategoryForm()
                    dismiss()
                }
                .buttonStyle(.appSecondary)

                Spacer()

                Button("Add Category") {
                    viewModel.addCategory()
                    dismiss()
                }
                .buttonStyle(.appPrimary)
                .disabled(viewModel.newCategoryName.isEmpty)
            }
        }
        .padding(Spacing.lg)
        .frame(width: 400, height: 450)
    }
}

// MARK: - Add Tag Sheet

struct AddTagSheet: View {
    @Bindable var viewModel: TagsCategoriesViewModel
    @Environment(\.dismiss) private var dismiss

    // 预设颜色
    let colors = [
        "2563EB", "10B981", "F59E0B", "EF4444", "8B5CF6",
        "EC4899", "06B6D4", "84CC16", "F97316", "6366F1"
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Add Tag")
                    .font(.h3)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Name Input
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                TextField("Tag name", text: $viewModel.newTagName)
                    .textFieldStyle(.roundedBorder)
            }

            // Color Selection
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: Spacing.sm) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: { viewModel.newTagColor = color }) {
                            Circle()
                                .fill(Color(nsColor: NSColor(hex: color)))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.newTagColor == color ? Color.textPrimary : Color.clear, lineWidth: 2)
                                        .padding(2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Preview
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                HStack {
                    Circle()
                        .fill(Color(nsColor: NSColor(hex: viewModel.newTagColor)))
                        .frame(width: 8, height: 8)

                    Text(viewModel.newTagName.isEmpty ? "Tag Name" : viewModel.newTagName)
                        .font(.bodySmall)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color(nsColor: NSColor(hex: viewModel.newTagColor)).opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()

            // Actions
            HStack {
                Button("Cancel") {
                    viewModel.resetTagForm()
                    dismiss()
                }
                .buttonStyle(.appSecondary)

                Spacer()

                Button("Add Tag") {
                    viewModel.addTag()
                    dismiss()
                }
                .buttonStyle(.appPrimary)
                .disabled(viewModel.newTagName.isEmpty)
            }
        }
        .padding(Spacing.lg)
        .frame(width: 400, height: 350)
    }
}

#Preview {
    TagsCategoriesView(storageService: StorageService())
        .environment(AppState())
        .frame(width: 800, height: 600)
}
