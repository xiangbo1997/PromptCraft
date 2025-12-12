import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: HistoryViewModel
    @State private var showingClearConfirmation: Bool = false
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    init(storageService: StorageService) {
        _viewModel = State(initialValue: HistoryViewModel(storageService: storageService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header & Filters
            VStack(spacing: Spacing.md) {
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock")
                            .foregroundStyle(Color.primaryApp)
                        Text(localization.l("history.title"))
                            .font(.h2)
                            .foregroundStyle(Color.textPrimary)
                    }

                    Spacer()

                    // 统计信息
                    Text("\(viewModel.filteredPrompts.count) / \(viewModel.prompts.count)")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)

                    // 清空按钮
                    if !viewModel.prompts.isEmpty {
                        Button(action: { showingClearConfirmation = true }) {
                            Label(localization.l("history.clear.all"), systemImage: "trash")
                                .foregroundStyle(Color.error)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.errorBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                // 筛选栏
                HStack(spacing: Spacing.md) {
                    // 搜索框
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textSecondary)
                            .font(.system(size: 14))

                        TextField(localization.l("common.search"), text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()

                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.border, lineWidth: 1)
                    )

                    // 日期筛选
                    Picker("Date", selection: $viewModel.selectedDateFilter) {
                        ForEach(DateFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)

                    // 模式筛选
                    Picker("Mode", selection: $viewModel.selectedModeFilter) {
                        Text("All Modes").tag(nil as OptimizeMode?)
                        ForEach(OptimizeMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode as OptimizeMode?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)

                    // 清除筛选
                    if viewModel.selectedDateFilter != .all || viewModel.selectedModeFilter != nil || !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.clearFilters() }) {
                            Label("Clear", systemImage: "xmark")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.primaryApp)
                    }

                    Spacer()
                }
            }
            .padding(Spacing.lg)
            .background(Color.backgroundApp)

            Divider()

            // MARK: - Content Area
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.filteredPrompts.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(viewModel.groupedPrompts, id: \.0) { dateGroup, prompts in
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                // 日期标题
                                Text(dateGroup)
                                    .font(.h4)
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(.leading, Spacing.xs)

                                // 该日期下的提示词
                                ForEach(prompts) { prompt in
                                    HistoryRow(
                                        prompt: prompt,
                                        onCopy: {
                                            appState.clipboardService.copy(prompt.optimizedContent)
                                            ToastManager.shared.success(localization.l("toast.copied"))
                                        },
                                        onFavorite: { viewModel.toggleFavorite(prompt) },
                                        onDelete: { viewModel.deletePrompt(prompt) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .background(Color.backgroundApp)
        .onAppear { viewModel.loadData() }
        .alert(localization.l("history.clear.all"), isPresented: $showingClearConfirmation) {
            Button(localization.l("common.cancel"), role: .cancel) {}
            Button(localization.l("common.delete"), role: .destructive) {
                viewModel.deleteAllHistory()
            }
        } message: {
            Text(localization.l("common.warning"))
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(localization.l("common.loading"))
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundStyle(Color.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text(localization.l("history.empty.message"))
                    .font(.h4)
                    .foregroundStyle(Color.textPrimary)
            }

            if viewModel.selectedDateFilter != .all || viewModel.selectedModeFilter != nil || !viewModel.searchText.isEmpty {
                Button("Clear") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
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
    }
}

// MARK: - HistoryRow View

struct HistoryRow: View {
    let prompt: Prompt
    let onCopy: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isHovering: Bool = false
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // 可编辑标题
                    EditableTitle(
                        title: prompt.title.isEmpty ? "Untitled Prompt" : prompt.title,
                        font: .bodyLarge,
                        fontWeight: .medium
                    ) { newTitle in
                        prompt.title = newTitle
                        prompt.updatedAt = Date()
                        try? modelContext.save()
                    }

                    HStack(spacing: Spacing.sm) {
                        // 模式标签
                        Text(prompt.optimizeMode.localizedName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryApp.opacity(0.1))
                            .foregroundStyle(Color.primaryApp)
                            .clipShape(Capsule())

                        // 时间
                        Text(prompt.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)

                        // 使用次数
                        if prompt.usageCount > 0 {
                            Text("x\(prompt.usageCount)")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: Spacing.sm) {
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

                    // 收藏按钮
                    Button(action: onFavorite) {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(prompt.isFavorite ? Color.warning : Color.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.backgroundApp.opacity(isHovering ? 1 : 0))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help(prompt.isFavorite ? "Remove from Favorites" : "Add to Favorites")

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
                    .help("Delete")
                }
                .opacity(isHovering ? 1 : 0.6)
            }

            // Original Prompt (collapsed by default)
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Original:")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    Text(prompt.originalContent)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.sm)
                        .background(Color.backgroundApp)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }

            // Optimized Prompt
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Optimized:")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)

                Text(prompt.optimizedContent)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(isExpanded ? nil : 2)
            }

            // Expand/Collapse Button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Less" : "More")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundStyle(Color.primaryApp)
            }
            .buttonStyle(.plain)
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
        .contextMenu {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button(action: onFavorite) {
                Label(prompt.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: prompt.isFavorite ? "star.slash" : "star")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HistoryView(storageService: StorageService())
        .environment(AppState())
        .frame(width: 800, height: 600)
}
