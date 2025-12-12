# PromptCraft - UI 设计规范文档

## 文档信息

- **项目名称**: PromptCraft
- **文档版本**: v1.0
- **创建日期**: 2025-12-02
- **最后更新**: 2025-12-02

---

## 目录

1. [设计原则](#1-设计原则)
2. [色彩系统](#2-色彩系统)
3. [字体排版](#3-字体排版)
4. [间距系统](#4-间距系统)
5. [组件规范](#5-组件规范)
6. [图标系统](#6-图标系统)
7. [动画效果](#7-动画效果)
8. [响应式设计](#8-响应式设计)
9. [无障碍设计](#9-无障碍设计)
10. [设计资源](#10-设计资源)

---

## 1. 设计原则

### 1.1 核心原则

#### 简洁至上 (Simplicity First)
- 界面元素精简，避免视觉噪音
- 每个屏幕专注于单一任务
- 使用留白增强可读性

#### 原生体验 (Native Feel)
- 遵循 macOS Human Interface Guidelines
- 使用系统原生控件和交互模式
- 支持系统级特性（深色模式、辅助功能等）

#### 高效操作 (Efficiency)
- 减少操作步骤
- 提供快捷键支持
- 智能默认值

#### 即时反馈 (Immediate Feedback)
- 所有操作提供视觉反馈
- 加载状态清晰可见
- 错误提示友好明确

### 1.2 设计语言

```
视觉风格：现代、简洁、专业
设计关键词：清晰、高效、优雅
参考应用：Bear、Things 3、Craft、Arc Browser
```

---

## 2. 色彩系统

### 2.1 主色调

#### 浅色模式 (Light Mode)

```swift
// 主色
Primary: #007AFF          // 系统蓝色
PrimaryHover: #0051D5     // 悬浮状态
PrimaryPressed: #004DB3   // 按下状态

// 辅助色
Secondary: #5856D6        // 紫色
Success: #34C759          // 绿色
Warning: #FF9500          // 橙色
Error: #FF3B30            // 红色

// 中性色
Background: #FFFFFF       // 背景
Surface: #F5F5F7          // 表面
Border: #E5E5EA           // 边框
Divider: #D1D1D6          // 分割线

// 文字色
TextPrimary: #000000      // 主要文字
TextSecondary: #3C3C43    // 次要文字 (60% opacity)
TextTertiary: #3C3C43     // 三级文字 (30% opacity)
TextDisabled: #3C3C43     // 禁用文字 (18% opacity)
```

#### 深色模式 (Dark Mode)

```swift
// 主色
Primary: #0A84FF          // 系统蓝色（深色模式）
PrimaryHover: #409CFF
PrimaryPressed: #66B3FF

// 辅助色
Secondary: #5E5CE6
Success: #32D74B
Warning: #FF9F0A
Error: #FF453A

// 中性色
Background: #1C1C1E       // 背景
Surface: #2C2C2E          // 表面
Border: #38383A           // 边框
Divider: #48484A          // 分割线

// 文字色
TextPrimary: #FFFFFF      // 主要文字
TextSecondary: #EBEBF5    // 次要文字 (60% opacity)
TextTertiary: #EBEBF5     // 三级文字 (30% opacity)
TextDisabled: #EBEBF5     // 禁用文字 (18% opacity)
```

### 2.2 语义化颜色

```swift
// 状态颜色
InfoBackground: rgba(0, 122, 255, 0.1)
SuccessBackground: rgba(52, 199, 89, 0.1)
WarningBackground: rgba(255, 149, 0, 0.1)
ErrorBackground: rgba(255, 59, 48, 0.1)

// 交互颜色
HoverBackground: rgba(0, 0, 0, 0.05)    // 浅色模式
HoverBackgroundDark: rgba(255, 255, 255, 0.1)  // 深色模式
SelectedBackground: rgba(0, 122, 255, 0.15)
FocusRing: #007AFF
```

### 2.3 标签颜色

```swift
// 预设标签颜色（支持深浅色模式）
TagColors = [
    "blue": (#007AFF, #0A84FF),
    "purple": (#5856D6, #5E5CE6),
    "pink": (#FF2D55, #FF375F),
    "red": (#FF3B30, #FF453A),
    "orange": (#FF9500, #FF9F0A),
    "yellow": (#FFCC00, #FFD60A),
    "green": (#34C759, #32D74B),
    "teal": (#5AC8FA, #64D2FF),
    "gray": (#8E8E93, #98989D)
]
```

### 2.4 渐变色

```swift
// 装饰性渐变
GradientPrimary: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
GradientSuccess: linear-gradient(135deg, #11998e 0%, #38ef7d 100%)
GradientWarning: linear-gradient(135deg, #f093fb 0%, #f5576c 100%)
```

---

## 3. 字体排版

### 3.1 字体家族

```swift
// 系统字体
Primary: SF Pro (macOS 系统字体)
Monospace: SF Mono (等宽字体，用于代码)
Rounded: SF Pro Rounded (圆角字体，用于数字)

// 中文字体
Chinese: PingFang SC (苹方-简)
```

### 3.2 字体大小

```swift
// 标题
H1: 28pt / Bold / Line Height 34pt
H2: 22pt / Bold / Line Height 28pt
H3: 18pt / Semibold / Line Height 24pt
H4: 16pt / Semibold / Line Height 22pt

// 正文
Body: 14pt / Regular / Line Height 20pt
BodyLarge: 16pt / Regular / Line Height 22pt
BodySmall: 12pt / Regular / Line Height 18pt

// 辅助文字
Caption: 11pt / Regular / Line Height 16pt
Footnote: 10pt / Regular / Line Height 14pt

// 按钮
ButtonLarge: 16pt / Medium
ButtonMedium: 14pt / Medium
ButtonSmall: 12pt / Medium
```

### 3.3 字重

```swift
Light: 300
Regular: 400
Medium: 500
Semibold: 600
Bold: 700
```

### 3.4 排版规范

```swift
// 段落间距
ParagraphSpacing: 12pt

// 字母间距
LetterSpacing: 0 (默认)
LetterSpacingTight: -0.5pt (标题)
LetterSpacingWide: 0.5pt (大写字母)

// 最大行宽
MaxLineWidth: 680pt (提高可读性)
```

---

## 4. 间距系统

### 4.1 基础间距

使用 8pt 网格系统：

```swift
// 间距单位
Space0: 0pt
Space1: 4pt    // 0.5x
Space2: 8pt    // 1x (基础单位)
Space3: 12pt   // 1.5x
Space4: 16pt   // 2x
Space5: 20pt   // 2.5x
Space6: 24pt   // 3x
Space8: 32pt   // 4x
Space10: 40pt  // 5x
Space12: 48pt  // 6x
Space16: 64pt  // 8x
```

### 4.2 组件内边距

```swift
// 按钮内边距
ButtonPaddingSmall: 6pt 12pt
ButtonPaddingMedium: 8pt 16pt
ButtonPaddingLarge: 10pt 20pt

// 输入框内边距
InputPadding: 8pt 12pt

// 卡片内边距
CardPadding: 16pt

// 面板内边距
PanelPadding: 20pt
```

### 4.3 布局间距

```swift
// 组件间距
ComponentSpacingTight: 8pt
ComponentSpacingNormal: 16pt
ComponentSpacingLoose: 24pt

// 区块间距
SectionSpacing: 32pt

// 页面边距
PageMargin: 20pt
```

---

## 5. 组件规范

### 5.1 按钮 (Button)

#### 主要按钮 (Primary Button)

```swift
// 样式
Background: Primary Color
TextColor: White
Height: 32pt (Medium) / 28pt (Small) / 36pt (Large)
BorderRadius: 6pt
Font: Medium

// 状态
Normal: Background = Primary
Hover: Background = PrimaryHover
Pressed: Background = PrimaryPressed
Disabled: Opacity = 0.5

// 代码示例
Button("优化") {
    // Action
}
.buttonStyle(.borderedProminent)
.controlSize(.regular)
```

#### 次要按钮 (Secondary Button)

```swift
// 样式
Background: Transparent
TextColor: Primary
Border: 1pt solid Border
Height: 32pt
BorderRadius: 6pt

// 代码示例
Button("取消") {
    // Action
}
.buttonStyle(.bordered)
```

#### 文字按钮 (Text Button)

```swift
// 样式
Background: Transparent
TextColor: Primary
No Border

// 代码示例
Button("了解更多") {
    // Action
}
.buttonStyle(.plain)
```

### 5.2 输入框 (TextField)

```swift
// 样式
Height: 32pt
Padding: 8pt 12pt
Background: Surface
Border: 1pt solid Border
BorderRadius: 6pt
Font: Body (14pt)

// 状态
Normal: Border = Border
Focus: Border = Primary, Shadow
Error: Border = Error
Disabled: Opacity = 0.5

// 代码示例
TextField("输入提示词...", text: $inputText)
    .textFieldStyle(.roundedBorder)
    .frame(height: 32)
```

### 5.3 文本区域 (TextEditor)

```swift
// 样式
MinHeight: 100pt
Padding: 12pt
Background: Surface
Border: 1pt solid Border
BorderRadius: 8pt
Font: Body (14pt)
LineHeight: 20pt

// 代码示例
TextEditor(text: $content)
    .frame(minHeight: 100)
    .padding(12)
    .background(Color(.surface))
    .cornerRadius(8)
```

### 5.4 下拉选择器 (Picker)

```swift
// 样式
Height: 32pt
Padding: 8pt 12pt
Background: Surface
Border: 1pt solid Border
BorderRadius: 6pt

// 代码示例
Picker("优化模式", selection: $selectedMode) {
    ForEach(OptimizeMode.allCases) { mode in
        Text(mode.rawValue).tag(mode)
    }
}
.pickerStyle(.menu)
```

### 5.5 卡片 (Card)

```swift
// 样式
Background: Surface
Border: 1pt solid Border (可选)
BorderRadius: 12pt
Padding: 16pt
Shadow: 0 2pt 8pt rgba(0,0,0,0.08)

// 悬浮效果
Hover: Shadow = 0 4pt 16pt rgba(0,0,0,0.12)

// 代码示例
VStack(alignment: .leading, spacing: 8) {
    Text("标题")
        .font(.headline)
    Text("内容")
        .font(.body)
}
.padding(16)
.background(Color(.surface))
.cornerRadius(12)
.shadow(radius: 4)
```

### 5.6 列表项 (List Item)

```swift
// 样式
Height: 60pt (最小)
Padding: 12pt 16pt
Background: Surface
Divider: 1pt solid Divider

// 悬浮效果
Hover: Background = HoverBackground

// 代码示例
List(prompts) { prompt in
    PromptRow(prompt: prompt)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
}
.listStyle(.plain)
```

### 5.7 标签 (Tag)

```swift
// 样式
Height: 24pt
Padding: 4pt 8pt
Background: TagColor with 0.15 opacity
TextColor: TagColor
BorderRadius: 4pt
Font: Caption (11pt)

// 代码示例
Text("#编程")
    .font(.caption)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.blue.opacity(0.15))
    .foregroundColor(.blue)
    .cornerRadius(4)
```

### 5.8 Toast 提示

```swift
// 样式
MinWidth: 200pt
MaxWidth: 400pt
Padding: 12pt 16pt
Background: rgba(0, 0, 0, 0.85) (浅色模式)
Background: rgba(255, 255, 255, 0.85) (深色模式)
TextColor: White (浅色) / Black (深色)
BorderRadius: 8pt
Shadow: 0 4pt 12pt rgba(0,0,0,0.15)
Backdrop: Blur 10pt

// 动画
Duration: 1.5s
FadeIn: 0.2s
FadeOut: 0.3s

// 代码示例
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .cornerRadius(8)
            .shadow(radius: 4)
    }
}
```

### 5.9 模态对话框 (Modal)

```swift
// 样式
Width: 480pt (默认)
Padding: 24pt
Background: Background
BorderRadius: 12pt
Shadow: 0 8pt 32pt rgba(0,0,0,0.2)
Backdrop: rgba(0, 0, 0, 0.4)

// 代码示例
.sheet(isPresented: $showModal) {
    VStack(spacing: 20) {
        Text("标题")
            .font(.title2)
        Text("内容")
            .font(.body)
        HStack {
            Button("取消") { }
            Button("确定") { }
        }
    }
    .padding(24)
    .frame(width: 480)
}
```

### 5.10 搜索框 (SearchField)

```swift
// 样式
Height: 32pt
Padding: 8pt 12pt 8pt 32pt (左侧留图标空间)
Background: Surface
Border: 1pt solid Border
BorderRadius: 16pt (圆角)
Icon: magnifyingglass (左侧)
ClearButton: xmark.circle.fill (右侧)

// 代码示例
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
    TextField("搜索提示词...", text: $searchText)
    if !searchText.isEmpty {
        Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
        }
    }
}
.padding(8)
.background(Color(.surface))
.cornerRadius(16)
```

---

## 6. 图标系统

### 6.1 图标库

使用 **SF Symbols 5.0**

### 6.2 图标尺寸

```swift
// 尺寸规范
IconSmall: 12pt
IconMedium: 16pt
IconLarge: 20pt
IconXLarge: 24pt

// 按钮图标
ButtonIcon: 16pt (Medium Button)
ButtonIconSmall: 14pt (Small Button)
ButtonIconLarge: 18pt (Large Button)
```

### 6.3 常用图标

```swift
// 功能图标
Optimize: "sparkles"
Library: "books.vertical"
Settings: "gearshape"
Search: "magnifyingglass"
Add: "plus"
Delete: "trash"
Edit: "pencil"
Copy: "doc.on.doc"
Save: "square.and.arrow.down"
Export: "square.and.arrow.up"
Import: "square.and.arrow.down.on.square"

// 状态图标
Success: "checkmark.circle.fill"
Error: "xmark.circle.fill"
Warning: "exclamationmark.triangle.fill"
Info: "info.circle.fill"

// 分类图标
General: "star.fill"
Writing: "pencil"
Coding: "chevron.left.forwardslash.chevron.right"
Translation: "globe"
Marketing: "megaphone.fill"
Learning: "book.fill"
Work: "briefcase.fill"

// 导航图标
Back: "chevron.left"
Forward: "chevron.right"
Up: "chevron.up"
Down: "chevron.down"
Close: "xmark"
Menu: "line.3.horizontal"

// 交互图标
Favorite: "star" / "star.fill"
Filter: "line.3.horizontal.decrease.circle"
Sort: "arrow.up.arrow.down"
More: "ellipsis"
```

### 6.4 图标使用规范

```swift
// 单色图标
Image(systemName: "sparkles")
    .font(.system(size: 16))
    .foregroundColor(.primary)

// 多色图标
Image(systemName: "star.fill")
    .symbolRenderingMode(.multicolor)

// 可变颜色图标
Image(systemName: "wifi")
    .symbolRenderingMode(.hierarchical)
    .foregroundColor(.blue)
```

---

## 7. 动画效果

### 7.1 动画时长

```swift
// 标准时长
Fast: 0.15s        // 快速交互
Normal: 0.25s      // 标准动画
Slow: 0.35s        // 慢速动画
VerySlow: 0.5s     // 页面转场

// 缓动函数
EaseInOut: .easeInOut
EaseOut: .easeOut
Spring: .spring(response: 0.3, dampingFraction: 0.7)
```

### 7.2 常用动画

#### 淡入淡出

```swift
.opacity(isVisible ? 1 : 0)
.animation(.easeInOut(duration: 0.25), value: isVisible)
```

#### 滑动

```swift
.offset(y: isVisible ? 0 : 20)
.opacity(isVisible ? 1 : 0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
```

#### 缩放

```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.15), value: isPressed)
```

#### 旋转

```swift
.rotationEffect(.degrees(isLoading ? 360 : 0))
.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
```

### 7.3 加载动画

```swift
// 进度指示器
ProgressView()
    .progressViewStyle(.circular)
    .scaleEffect(1.5)

// 自定义加载动画
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}
```

### 7.4 过渡效果

```swift
// 页面转场
.transition(.move(edge: .trailing))
.transition(.opacity)
.transition(.scale)

// 组合转场
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

---

## 8. 响应式设计

### 8.1 窗口尺寸

```swift
// 主窗口
MinWidth: 800pt
MinHeight: 600pt
DefaultWidth: 1000pt
DefaultHeight: 700pt

// 菜单栏面板
Width: 320pt
MaxHeight: 500pt

// 设置窗口
Width: 600pt
Height: 500pt
```

### 8.2 断点

```swift
// 窗口宽度断点
Compact: < 800pt
Regular: 800pt - 1200pt
Large: > 1200pt
```

### 8.3 自适应布局

```swift
// 侧边栏宽度
@State private var sidebarWidth: CGFloat = 220

// 响应式侧边栏
if horizontalSizeClass == .regular {
    NavigationSplitView {
        SidebarView()
    } detail: {
        ContentView()
    }
} else {
    NavigationStack {
        ContentView()
    }
}
```

---

## 9. 无障碍设计

### 9.1 颜色对比度

```swift
// WCAG AA 标准
NormalText: 对比度 ≥ 4.5:1
LargeText: 对比度 ≥ 3:1
UIComponents: 对比度 ≥ 3:1
```

### 9.2 VoiceOver 支持

```swift
// 添加辅助标签
Button(action: optimize) {
    Image(systemName: "sparkles")
}
.accessibilityLabel("优化提示词")
.accessibilityHint("点击优化当前输入的提示词")

// 辅助值
Text("\(prompts.count)")
    .accessibilityLabel("\(prompts.count) 个提示词")
```

### 9.3 键盘导航

```swift
// 焦点管理
@FocusState private var focusedField: Field?

TextField("输入", text: $input)
    .focused($focusedField, equals: .input)
    .onSubmit {
        focusedField = .result
    }
```

### 9.4 动态字体

```swift
// 支持系统字体大小调整
Text("标题")
    .font(.headline)
    .dynamicTypeSize(.large ... .xxxLarge)
```

---

## 10. 设计资源

### 10.1 设计工具

- **Figma**: 主要设计工具
- **Sketch**: 备选设计工具
- **SF Symbols**: 图标库

### 10.2 设计文件结构

```
PromptCraft-Design/
├── Design-System.fig          # 设计系统
├── Components.fig             # 组件库
├── Main-Window.fig            # 主窗口设计
├── MenuBar-Popover.fig        # 菜单栏面板
├── Settings.fig               # 设置页面
└── Assets/
    ├── Icons/                 # 图标资源
    ├── Images/                # 图片资源
    └── Mockups/               # 设计稿
```

### 10.3 导出规范

```swift
// 图标导出
Format: PDF (矢量)
Scale: 1x, 2x, 3x

// 图片导出
Format: PNG
Scale: 1x, 2x, 3x
Optimization: 压缩优化
```

### 10.4 设计 Token

```swift
// 使用设计 Token 管理样式
enum DesignToken {
    // 颜色
    static let primaryColor = Color("Primary")
    static let backgroundColor = Color("Background")
    
    // 间距
    static let spacing2 = CGFloat(8)
    static let spacing4 = CGFloat(16)
    
    // 圆角
    static let cornerRadiusSmall = CGFloat(4)
    static let cornerRadiusMedium = CGFloat(8)
    static let cornerRadiusLarge = CGFloat(12)
    
    // 阴影
    static let shadowSmall = Shadow(radius: 2, y: 1)
    static let shadowMedium = Shadow(radius: 4, y: 2)
    static let shadowLarge = Shadow(radius: 8, y: 4)
}
```

---

## 附录

### A. 设计检查清单

- [ ] 遵循 macOS HIG
- [ ] 支持深浅色模式
- [ ] 颜色对比度符合 WCAG AA
- [ ] 支持 VoiceOver
- [ ] 支持键盘导航
- [ ] 支持动态字体
- [ ] 响应式布局
- [ ] 动画流畅自然
- [ ] 图标清晰易懂
- [ ] 文字可读性好

### B. 常见问题

**Q: 如何确保深浅色模式的颜色正确？**
A: 使用 Asset Catalog 定义颜色，分别设置 Light 和 Dark Appearance。

**Q: 如何测试无障碍功能？**
A: 使用 Xcode 的 Accessibility Inspector 和 VoiceOver 进行测试。

**Q: 如何保持设计一致性？**
A: 使用设计系统和组件库，所有组件从统一的设计 Token 获取样式。

### C. 参考资源

- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

*文档版本: v1.0*
*创建日期: 2025-12-02*
*维护者: 设计团队*
