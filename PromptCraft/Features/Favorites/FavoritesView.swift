import SwiftUI
import SwiftData

/// Favorites 收藏页面
struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: FavoritesViewModel
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    init(storageService: StorageService) {
        _viewModel = State(initialValue: FavoritesViewModel(storageService: storageService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.warning)
                    Text(localization.l("favorites.title"))
                        .font(.h2)
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                // Search
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                        .font(.system(size: 14))

                    TextField(localization.l("common.search"), text: $viewModel.searchText)
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
                .frame(width: 250)

                Text("\(viewModel.favoritePrompts.count)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.lg)
            .background(Color.backgroundApp)

            Divider()

            // MARK: - Content
            if viewModel.isLoading {
                ProgressView(localization.l("common.loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.filteredPrompts.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.filteredPrompts) { prompt in
                            FavoritePromptCard(
                                prompt: prompt,
                                onCopy: {
                                    appState.clipboardService.copy(prompt.optimizedContent)
                                    ToastManager.shared.success(localization.l("toast.copied"))
                                },
                                onUnfavorite: { viewModel.toggleFavorite(prompt) },
                                onDelete: { viewModel.deletePrompt(prompt) }
                            )
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .background(Color.backgroundApp)
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "star")
                .font(.system(size: 64))
                .foregroundStyle(Color.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text(localization.l("favorites.empty.message"))
                    .font(.h4)
                    .foregroundStyle(Color.textPrimary)
            }

            if !viewModel.searchText.isEmpty {
                Button("Clear Search") {
                    viewModel.searchText = ""
                }
                .buttonStyle(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
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

// MARK: - Favorite Prompt Card

struct FavoritePromptCard: View {
    let prompt: Prompt
    let onCopy: () -> Void
    let onUnfavorite: () -> Void
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
                    EditableTitle(title: prompt.title) { newTitle in
                        prompt.title = newTitle
                        prompt.updatedAt = Date()
                        try? modelContext.save()
                    }

                    HStack(spacing: Spacing.sm) {
                        Label(prompt.optimizeMode.localizedName, systemImage: "wand.and.stars")
                            .font(.caption)
                            .foregroundStyle(Color.primaryApp)

                        Text("•")
                            .foregroundStyle(Color.textTertiary)

                        Text("Used \(prompt.usageCount) times")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        if let lastUsed = prompt.lastUsedAt {
                            Text("•")
                                .foregroundStyle(Color.textTertiary)

                            Text("Last: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: Spacing.sm) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")

                    Button(action: onUnfavorite) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.warning)
                    }
                    .buttonStyle(.plain)
                    .help("Remove from favorites")

                    Menu {
                        Button(action: onCopy) {
                            Label("Copy Optimized", systemImage: "doc.on.doc")
                        }
                        Button(action: onUnfavorite) {
                            Label("Remove from Favorites", systemImage: "star.slash")
                        }
                        Divider()
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
            }

            // Content Preview
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Optimized:")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)

                Text(prompt.optimizedContent)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(isExpanded ? nil : 3)

                if prompt.optimizedContent.count > 150 {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.caption)
                            .foregroundStyle(Color.primaryApp)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md)
            .background(Color.infoBackground.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            // Category & Tags
            if prompt.category != nil || !prompt.tags.isEmpty {
                HStack(spacing: Spacing.sm) {
                    if let category = prompt.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.border, lineWidth: 0.5))
                    }

                    ForEach(prompt.tags) { tag in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(nsColor: NSColor(hex: tag.color)))
                                .frame(width: 6, height: 6)
                            Text(tag.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: NSColor(hex: tag.color)).opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isHovering ? Color.warning.opacity(0.3) : Color.border, lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.shadowMd : Color.shadowSm, radius: isHovering ? 8 : 4, x: 0, y: 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    FavoritesView(storageService: StorageService())
        .environment(AppState())
        .frame(width: 800, height: 600)
}
