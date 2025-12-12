import SwiftUI

/// 可编辑标题组件
/// 点击标题进入编辑模式，支持回车确认或失焦保存
struct EditableTitle: View {
    let title: String
    let onSave: (String) -> Void

    // 样式配置
    var font: Font
    var fontWeight: Font.Weight
    var foregroundColor: Color
    var editBackgroundColor: Color
    var placeholder: String

    @State private var isEditing: Bool = false
    @State private var editingText: String = ""
    @FocusState private var isFocused: Bool

    /// 初始化可编辑标题组件
    /// - Parameters:
    ///   - title: 当前标题
    ///   - font: 标题字体，默认 .h4
    ///   - fontWeight: 字体粗细，默认 .medium
    ///   - foregroundColor: 文字颜色，默认 .textPrimary
    ///   - editBackgroundColor: 编辑模式背景色，默认 .surface
    ///   - placeholder: 占位文字，默认 "输入标题..."
    ///   - onSave: 保存回调，传入新标题
    init(
        title: String,
        font: Font = .h4,
        fontWeight: Font.Weight = .medium,
        foregroundColor: Color = .textPrimary,
        editBackgroundColor: Color = .surface,
        placeholder: String = "输入标题...",
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.font = font
        self.fontWeight = fontWeight
        self.foregroundColor = foregroundColor
        self.editBackgroundColor = editBackgroundColor
        self.placeholder = placeholder
        self.onSave = onSave
    }

    var body: some View {
        Group {
            if isEditing {
                TextField(placeholder, text: $editingText)
                    .font(font)
                    .fontWeight(fontWeight)
                    .foregroundStyle(foregroundColor)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(editBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.primaryApp, lineWidth: 1)
                    )
                    .focused($isFocused)
                    .onSubmit {
                        saveAndExitEditing()
                    }
                    .onChange(of: isFocused) { _, newValue in
                        if !newValue {
                            saveAndExitEditing()
                        }
                    }
            } else {
                Text(title.isEmpty ? placeholder : title)
                    .font(font)
                    .fontWeight(fontWeight)
                    .foregroundStyle(title.isEmpty ? Color.textTertiary : foregroundColor)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
                    .help("点击编辑标题")
            }
        }
    }

    private func startEditing() {
        editingText = title
        isEditing = true
        // 延迟设置焦点，确保 TextField 已渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
        }
    }

    private func saveAndExitEditing() {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != title {
            onSave(trimmed)
        }
        isEditing = false
    }
}

#Preview {
    VStack(spacing: 20) {
        EditableTitle(title: "这是一个测试标题") { newTitle in
            print("New title: \(newTitle)")
        }

        EditableTitle(title: "", font: .bodyLarge, fontWeight: .medium) { newTitle in
            print("New title: \(newTitle)")
        }
    }
    .padding()
}
