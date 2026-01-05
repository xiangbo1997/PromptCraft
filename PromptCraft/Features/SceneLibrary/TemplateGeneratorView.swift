import SwiftUI
import SwiftData

// MARK: - 模板生成器视图
/// 填空式的模板生成器，用户填写字段后生成内容
struct TemplateGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let template: SceneTemplate
    let aiService: AIServiceProtocol

    @State private var fieldValues: [String: String] = [:]
    @State private var generatedContent: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showExpertMode: Bool = false
    @State private var generatedPrompt: String = ""
    @State private var subscriptionService = SubscriptionService.shared

    private var categoryColor: Color {
        Color(nsColor: NSColor(hex: template.category.colorHex))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            header

            Divider()

            // 内容区
            HSplitView {
                // 左侧：输入表单
                inputForm
                    .frame(minWidth: 350, maxWidth: 450)

                // 右侧：生成结果
                outputArea
                    .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(Color.backgroundApp)
        .onAppear {
            initializeFieldValues()
        }
    }

    // MARK: - 头部
    private var header: some View {
        HStack(spacing: Spacing.md) {
            // 图标
            Image(systemName: template.icon)
                .font(.system(size: 24))
                .foregroundStyle(categoryColor)
                .frame(width: 48, height: 48)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // 标题和描述
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(template.name)
                        .font(.h3)
                        .foregroundStyle(Color.textPrimary)

                    // 分类标签
                    Text(template.category.displayName)
                        .font(.caption)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(template.description)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // 模式切换
            Toggle(isOn: $showExpertMode) {
                HStack(spacing: 4) {
                    Image(systemName: showExpertMode ? "eye" : "eye.slash")
                    Text(showExpertMode ? "专业模式" : "傻瓜模式")
                }
                .font(.bodySmall)
            }
            .toggleStyle(.switch)
            .help(showExpertMode ? "显示生成的提示词" : "隐藏提示词，只显示结果")

            // 关闭按钮
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.backgroundApp)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color.surface)
    }

    // MARK: - 输入表单
    private var inputForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // 表单标题
                HStack {
                    Image(systemName: "pencil.and.list.clipboard")
                        .foregroundStyle(categoryColor)
                    Text("填写信息")
                        .font(.h4)

                    Spacer()

                    // 清空按钮
                    Button("清空") {
                        clearFields()
                    }
                    .font(.bodySmall)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.textSecondary)
                }

                // 字段列表
                ForEach(template.fields) { field in
                    TemplateFieldView(
                        field: field,
                        value: binding(for: field.id),
                        accentColor: categoryColor
                    )
                }

                // 生成按钮
                Button(action: { Task { await generate() } }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGenerating ? "生成中..." : "一键生成")
                    }
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isFormValid ? categoryColor : Color.textDisabled
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid || isGenerating)

                // 错误提示
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.error)
                        Text(error)
                            .font(.bodySmall)
                            .foregroundStyle(Color.error)
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.errorBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }

                // 专业模式：显示生成的提示词
                if showExpertMode && !generatedPrompt.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(Color.textSecondary)
                            Text("生成的提示词")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)

                            Spacer()

                            Button(action: { copyToClipboard(generatedPrompt) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.textSecondary)
                        }

                        Text(generatedPrompt)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.backgroundApp)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.surface)
    }

    // MARK: - 输出区域
    private var outputArea: some View {
        VStack(spacing: 0) {
            // 输出头部
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(categoryColor)
                Text("生成结果")
                    .font(.h4)

                Spacer()

                if !generatedContent.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        // 复制按钮
                        Button(action: { copyToClipboard(generatedContent) }) {
                            Label("复制", systemImage: "doc.on.doc")
                                .font(.bodySmall)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border))

                        // 保存按钮
                        Button(action: { saveToLibrary() }) {
                            Label("保存", systemImage: "square.and.arrow.down")
                                .font(.bodySmall)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.surface)

            Divider()

            // 输出内容
            ScrollView {
                if generatedContent.isEmpty && !isGenerating {
                    // 空状态
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.textTertiary)

                        Text("填写左侧信息后点击生成")
                            .font(.bodyRegular)
                            .foregroundStyle(Color.textSecondary)

                        if let example = template.exampleOutput {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("示例输出")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)

                                Text(example)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(Spacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            }
                            .padding(.top, Spacing.lg)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Spacing.xl)
                } else {
                    // 生成的内容
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(generatedContent)
                            .font(.bodyRegular)
                            .foregroundStyle(Color.textPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isGenerating {
                            HStack(spacing: Spacing.sm) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("AI 正在生成...")
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .background(Color.backgroundApp)
        }
    }

    // MARK: - 辅助方法

    private func initializeFieldValues() {
        for field in template.fields {
            if let defaultValue = field.defaultValue {
                fieldValues[field.id] = defaultValue
            } else {
                fieldValues[field.id] = ""
            }
        }
    }

    private func binding(for fieldId: String) -> Binding<String> {
        Binding(
            get: { fieldValues[fieldId] ?? "" },
            set: { fieldValues[fieldId] = $0 }
        )
    }

    private var isFormValid: Bool {
        let missingFields = template.validateFields(fieldValues)
        return missingFields.isEmpty
    }

    private func clearFields() {
        for field in template.fields {
            fieldValues[field.id] = field.defaultValue ?? ""
        }
        generatedContent = ""
        generatedPrompt = ""
        errorMessage = nil
    }

    private func generate() async {
        guard isFormValid else { return }

        // 检查是否可以生成
        if !subscriptionService.canGenerate {
            errorMessage = "今日免费次数已用完，请升级 Pro 版继续使用"
            return
        }

        isGenerating = true
        errorMessage = nil
        generatedContent = ""

        // 生成提示词（用于专业模式显示）
        generatedPrompt = template.generatePrompt(with: fieldValues)

        do {
            let service = TemplateGenerationService(aiService: aiService)

            // 记录使用次数
            subscriptionService.recordGeneration()

            // 使用流式生成
            for try await chunk in service.generateStream(template: template, fieldValues: fieldValues) {
                generatedContent += chunk
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private func copyToClipboard(_ text: String) {
        appState.clipboardService.copy(text)
        ToastManager.shared.success("已复制到剪贴板")
    }

    private func saveToLibrary() {
        guard !generatedContent.isEmpty else {
            ToastManager.shared.error("没有可保存的内容")
            return
        }

        // 生成标题：使用模板名称 + 时间戳
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let timestamp = dateFormatter.string(from: Date())
        let title = "\(template.name) - \(timestamp)"

        // 创建新的 Prompt 对象
        let prompt = Prompt(
            title: title,
            originalContent: generatedPrompt.isEmpty ? template.generatePrompt(with: fieldValues) : generatedPrompt,
            optimizedContent: generatedContent,
            optimizeMode: .detailed  // 场景模板生成的内容默认使用详细模式
        )

        // 保存到 SwiftData
        modelContext.insert(prompt)

        do {
            try modelContext.save()
            ToastManager.shared.success("已保存到提示词库")
        } catch {
            ToastManager.shared.error("保存失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - 模板字段视图
struct TemplateFieldView: View {
    let field: TemplateField
    @Binding var value: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // 标签
            HStack(spacing: 4) {
                Text(field.label)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textPrimary)

                if field.isRequired {
                    Text("*")
                        .font(.bodySmall)
                        .foregroundStyle(Color.error)
                }
            }

            // 输入控件
            switch field.fieldType {
            case .text:
                TextField(field.placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)

            case .textarea:
                TextEditor(text: $value)
                    .font(.bodyRegular)
                    .scrollContentBackground(.hidden)
                    .background(Color.surface)
                    .frame(minHeight: 80, maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.border, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if value.isEmpty {
                            Text(field.placeholder)
                                .font(.bodyRegular)
                                .foregroundStyle(Color.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }

            case .select:
                Picker("", selection: $value) {
                    if value.isEmpty {
                        Text(field.placeholder).tag("")
                    }
                    ForEach(field.options ?? [], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.border, lineWidth: 1)
                )

            case .multiSelect:
                // 多选暂时用文本输入代替
                TextField(field.placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)

            case .number:
                TextField(field.placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)

            case .toggle:
                Toggle(field.placeholder, isOn: Binding(
                    get: { value == "true" },
                    set: { value = $0 ? "true" : "false" }
                ))
            }

            // 字数统计（仅 textarea）
            if field.fieldType == .textarea, let maxLength = field.maxLength {
                HStack {
                    Spacer()
                    Text("\(value.count)/\(maxLength)")
                        .font(.caption)
                        .foregroundStyle(value.count > maxLength ? Color.error : Color.textTertiary)
                }
            }
        }
    }
}

#Preview {
    TemplateGeneratorView(
        template: BuiltInTemplates.xiaohongshuTemplates[0],
        aiService: MockAIService()
    )
    .environment(AppState())
}
