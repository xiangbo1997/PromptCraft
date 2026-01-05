import SwiftUI

// MARK: - 场景库视图
/// 展示所有场景分类和模板的主视图
struct SceneLibraryView: View {
    @Environment(AppState.self) private var appState
    @State private var templateService = TemplateService.shared
    @State private var subscriptionService = SubscriptionService.shared
    @State private var selectedCategory: SceneCategory? = nil
    @State private var searchText: String = ""
    @State private var selectedTemplate: SceneTemplate? = nil
    @State private var showPaywall: Bool = false
    @State private var paywallReason: RestrictionReason = .dailyLimitReached

    var body: some View {
        HSplitView {
            // 左侧：分类列表
            categorySidebar
                .frame(minWidth: 200, maxWidth: 250)

            // 右侧：模板列表
            templateList
                .frame(minWidth: 400)
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateGeneratorView(
                template: template,
                aiService: appState.aiService
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                reason: paywallReason,
                subscriptionService: subscriptionService
            )
        }
    }

    // MARK: - 处理模板点击
    private func handleTemplateTap(_ template: SceneTemplate) {
        if let reason = subscriptionService.getRestrictionReason(for: template) {
            paywallReason = reason
            showPaywall = true
        } else {
            selectedTemplate = template
        }
    }

    // MARK: - 分类侧边栏
    private var categorySidebar: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)
                    .font(.system(size: 14))

                TextField("搜索模板...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
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
            .padding(Spacing.md)

            Divider()

            // 分类列表
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    // 全部模板
                    SceneCategoryRow(
                        icon: "square.grid.2x2",
                        title: "全部模板",
                        count: templateService.allTemplates.count,
                        color: Color.primaryApp,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    // 最近使用
                    if !templateService.recentTemplates.isEmpty {
                        SceneCategoryRow(
                            icon: "clock",
                            title: "最近使用",
                            count: templateService.recentTemplates.count,
                            color: Color.secondaryApp,
                            isSelected: false
                        ) {
                            // 显示最近使用的模板
                        }
                    }

                    // 我的收藏
                    if !templateService.favoriteTemplates().isEmpty {
                        SceneCategoryRow(
                            icon: "star.fill",
                            title: "我的收藏",
                            count: templateService.favoriteTemplates().count,
                            color: Color.warning,
                            isSelected: false
                        ) {
                            // 显示收藏的模板
                        }
                    }

                    Divider()
                        .padding(.vertical, Spacing.sm)

                    // 场景分类
                    Text("场景分类")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.xs)

                    ForEach(SceneCategory.allCases) { category in
                        SceneCategoryRow(
                            icon: category.icon,
                            title: category.displayName,
                            count: templateService.templates(for: category).count,
                            color: Color(nsColor: NSColor(hex: category.colorHex)),
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .background(Color.backgroundApp)
    }

    // MARK: - 模板列表
    private var templateList: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(selectedCategory?.displayName ?? "全部模板")
                        .font(.h3)
                        .foregroundStyle(Color.textPrimary)

                    Text(selectedCategory?.description ?? "浏览所有可用的场景模板")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // 使用量指示器
                UsageIndicatorView(subscriptionService: subscriptionService)

                // 热门模板标签
                if selectedCategory == nil {
                    HStack(spacing: Spacing.sm) {
                        Text("热门")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.warningBackground)
                            .foregroundStyle(Color.warning)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.surface)

            Divider()

            // 模板网格
            ScrollView {
                let templates = filteredTemplates
                if templates.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Spacing.md),
                            GridItem(.flexible(), spacing: Spacing.md)
                        ],
                        spacing: Spacing.md
                    ) {
                        ForEach(templates) { template in
                            TemplateCard(
                                template: template,
                                isFavorite: templateService.isFavorite(templateId: template.id),
                                onTap: {
                                    handleTemplateTap(template)
                                },
                                onFavorite: {
                                    templateService.toggleFavorite(templateId: template.id)
                                }
                            )
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .background(Color.backgroundApp)
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)

            Text("没有找到匹配的模板")
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)

            if !searchText.isEmpty {
                Button("清除搜索") {
                    searchText = ""
                }
                .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }

    // MARK: - 过滤后的模板
    private var filteredTemplates: [SceneTemplate] {
        var templates: [SceneTemplate]

        if let category = selectedCategory {
            templates = templateService.templates(for: category)
        } else {
            templates = templateService.allTemplates
        }

        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return templates
    }
}

// MARK: - 场景分类行
struct SceneCategoryRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? color : color.opacity(0.1))
                    )

                Text(title)
                    .font(.bodyRegular)
                    .foregroundStyle(isSelected ? Color.primaryApp : Color.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.backgroundApp)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(isSelected ? Color.primaryApp.opacity(0.1) : (isHovering ? Color.surface : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .padding(.horizontal, Spacing.sm)
    }
}

// MARK: - 模板卡片
struct TemplateCard: View {
    let template: SceneTemplate
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    @State private var isHovering = false

    private var categoryColor: Color {
        Color(nsColor: NSColor(hex: template.category.colorHex))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // 头部：图标和收藏
                HStack {
                    // 图标
                    Image(systemName: template.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(categoryColor)
                        .frame(width: 40, height: 40)
                        .background(categoryColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    // 收藏按钮
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(isFavorite ? Color.warning : Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering || isFavorite ? 1 : 0)

                    // Premium 标签
                    if template.isPremium {
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.warning)
                            .clipShape(Capsule())
                    }
                }

                // 标题
                Text(template.name)
                    .font(.h4)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                // 描述
                Text(template.description)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)

                // 标签
                HStack(spacing: Spacing.xs) {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.backgroundApp)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // 使用次数
                    if TemplateService.shared.usageCount(for: template.id) > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(TemplateService.shared.usageCount(for: template.id))")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.warning)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovering ? categoryColor.opacity(0.5) : Color.border, lineWidth: isHovering ? 2 : 1)
            )
            .shadow(color: isHovering ? Color.shadowMd : Color.clear, radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    SceneLibraryView()
        .environment(AppState())
        .frame(width: 900, height: 700)
}
