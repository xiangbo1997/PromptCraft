import SwiftUI
import SwiftData

struct OptimizeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OptimizeViewModel?
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    var body: some View {
        Group {
            if let vm = viewModel {
                OptimizeContentView(viewModel: vm, appState: appState, localization: localization)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            initializeViewModelIfNeeded()
        }
    }

    private func initializeViewModelIfNeeded() {
        if viewModel == nil {
            // 捕获 appState 引用，每次调用时获取最新的 aiService
            let state = appState
            viewModel = OptimizeViewModel(
                aiServiceProvider: { state.aiService },
                storageService: state.storageService
            )
        }
    }
}

// 将内容抽取为单独的视图，接收非可选的 viewModel
private struct OptimizeContentView: View {
    @Bindable var viewModel: OptimizeViewModel
    let appState: AppState
    let localization: LocalizationService

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // MARK: - Header
                HStack {
                    Text(localization.l("optimize.title"))
                        .font(.h2)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    HStack(spacing: Spacing.sm) {
                        // Clear Button
                        Button {
                            viewModel.clearAll()
                        } label: {
                            Label(localization.l("common.delete"), systemImage: "trash")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border, lineWidth: 1))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.inputText.isEmpty && viewModel.outputText.isEmpty)

                        // Save Button
                        Button {
                            viewModel.savePrompt()
                            if viewModel.didSavePrompt {
                                ToastManager.shared.success(localization.l("toast.saved"))
                            }
                        } label: {
                            Label(localization.l("common.save"), systemImage: "square.and.arrow.down")
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.didSavePrompt ? Color.success : Color.primaryApp)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.outputText.isEmpty)
                    }
                }

                // MARK: - Optimize Section
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(Color.primaryApp)
                        Text(localization.l("optimize.title"))
                            .font(.h4)
                    }

                    // Mode Selection
                    HStack(spacing: 0) {
                        ForEach(OptimizeMode.allCases, id: \.self) { mode in
                            Button(action: { viewModel.selectedMode = mode }) {
                                Text(mode.localizedName)
                                    .font(.bodySmall)
                                    .fontWeight(viewModel.selectedMode == mode ? .medium : .regular)
                                    .foregroundStyle(viewModel.selectedMode == mode ? .white : Color.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedMode == mode ? Color.primaryApp : Color.backgroundApp)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.border, lineWidth: 1))

                    // Input
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(localization.l("optimize.input.placeholder"))
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(viewModel.inputText.count) characters")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }

                        TextEditor(text: $viewModel.inputText)
                            .font(.bodyRegular)
                            .scrollContentBackground(.hidden)
                            .background(Color.surface)
                            .foregroundStyle(Color.textPrimary)
                            .frame(minHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.border, lineWidth: 1))
                    }

                    // Swap Button (when both input and output exist)
                    if !viewModel.outputText.isEmpty {
                        HStack {
                            Spacer()
                            Button {
                                viewModel.swapInputOutput()
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(Color.primaryApp)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Swap input and output")
                            Spacer()
                        }
                    }

                    // Output (if exists)
                    if !viewModel.outputText.isEmpty {
                        // 标题区域
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("标题")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                Spacer()
                                if viewModel.isGeneratingTitle {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("生成中...")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                            }

                            // 可编辑标题
                            TextField("输入标题...", text: $viewModel.generatedTitle)
                                .font(.bodyLarge)
                                .fontWeight(.medium)
                                .textFieldStyle(.plain)
                                .padding(Spacing.sm)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(localization.l("optimize.output.placeholder"))
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                Spacer()
                                Text("\(viewModel.outputText.count) characters")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)

                                // 字符变化指示
                                let diff = viewModel.outputText.count - viewModel.inputText.count
                                if diff != 0 {
                                    Text(diff > 0 ? "+\(diff)" : "\(diff)")
                                        .font(.caption)
                                        .foregroundStyle(diff > 0 ? Color.warning : Color.success)
                                }
                            }

                            TextEditor(text: .constant(viewModel.outputText))
                                .font(.bodyRegular)
                                .scrollContentBackground(.hidden)
                                .background(Color.infoBackground.opacity(0.1))
                                .foregroundStyle(Color.textPrimary)
                                .frame(minHeight: 120)
                                .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.primaryApp.opacity(0.3), lineWidth: 1))
                        }
                    }

                    // Actions
                    HStack {
                        Spacer()

                        // Re-optimize Button
                        if !viewModel.outputText.isEmpty {
                            Button {
                                Task { await viewModel.reoptimize() }
                            } label: {
                                Label("Re-optimize", systemImage: "arrow.clockwise")
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.border, lineWidth: 1))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading)
                        }

                        // Copy Button
                        Button {
                            appState.clipboardService.copy(viewModel.outputText)
                            if appState.showCopyToast {
                                ToastManager.shared.success(localization.l("toast.copied"))
                            }
                        } label: {
                            Label(localization.l("common.copy"), systemImage: "doc.on.doc")
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.border, lineWidth: 1))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.outputText.isEmpty)

                        // Optimize Button - 使用 Group 包裹样式以确保点击区域正确
                        Button {
                            Task {
                                await viewModel.optimize()
                            }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Label(localization.l("optimize.button"), systemImage: "bolt.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.inputText.isEmpty ? Color.gray : Color.primaryApp)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.white)
                            Text(error)
                                .font(.bodySmall)
                                .foregroundStyle(.white)
                            Spacer()
                            Button(action: { viewModel.errorMessage = nil }) {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color.error)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                }
                .padding(Spacing.lg)
                .cardStyle()

                // MARK: - Statistics Section
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(Color.primaryApp)
                        Text("Statistics")
                            .font(.h4)
                    }

                    HStack(spacing: Spacing.xl) {
                        StatItem(
                            value: "\(viewModel.totalOptimizations)",
                            label: "Optimized"
                        )
                        StatItem(
                            value: viewModel.totalOptimizations > 0 ? String(format: "%.0f%%", viewModel.successRate) : "-",
                            label: "Success"
                        )
                        StatItem(
                            value: "\(viewModel.savedTemplates)",
                            label: "Saved"
                        )
                        StatItem(
                            value: viewModel.totalOptimizations > 0 ? "Active" : "-",
                            label: "Status"
                        )
                    }
                    .padding(.vertical, Spacing.md)
                }
                .padding(Spacing.lg)
                .cardStyle()

                // MARK: - Recent Prompts
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.primaryApp)
                        Text(localization.l("menubar.recent"))
                            .font(.h4)
                        Spacer()

                        if !viewModel.recentPrompts.isEmpty {
                            Button(action: { viewModel.loadStatistics() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.recentPrompts.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.textTertiary)
                                Text(localization.l("library.empty.message"))
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.vertical, Spacing.lg)
                            Spacer()
                        }
                    } else {
                        ForEach(viewModel.recentPrompts) { prompt in
                            RecentPromptRow(
                                title: prompt.title,
                                desc: prompt.optimizedContent,
                                tags: [prompt.optimizeMode.localizedName],
                                onUse: { viewModel.usePrompt(prompt) },
                                onCopy: {
                                    appState.clipboardService.copy(prompt.optimizedContent)
                                    ToastManager.shared.success(localization.l("toast.copied"))
                                }
                            )
                        }
                    }
                }
                .padding(Spacing.lg)
                .cardStyle()

                // MARK: - Menu Bar Access
                HStack {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.primaryApp)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.l("menubar.open.main"))
                            .font(.h4)
                        Text(localization.l("settings.hotkeys"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Text("Global Shortcut: ⌘ + ⇧ + P")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundApp)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(Spacing.lg)
                .cardStyle()

            }
            .padding(Spacing.lg)
        }
        .background(Color.backgroundApp)
        .onAppear {
            viewModel.loadStatistics()
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecentPromptRow: View {
    let title: String
    let desc: String
    let tags: [String]
    var onUse: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil

    @State private var isHovering: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 8) {
                    if let onUse = onUse {
                        Button(action: onUse) {
                            Image(systemName: "arrow.uturn.left")
                                .help("Use this prompt")
                        }
                    }
                    if let onCopy = onCopy {
                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                                .help("Copy to clipboard")
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.textSecondary)
                .opacity(isHovering ? 1 : 0.5)
            }

            Text(desc)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)

            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryApp.opacity(0.1))
                        .foregroundStyle(Color.primaryApp)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(isHovering ? Color.primaryApp.opacity(0.3) : Color.border, lineWidth: 0.5))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    OptimizeView()
        .environment(AppState())
        .frame(width: 800, height: 1000)
}
