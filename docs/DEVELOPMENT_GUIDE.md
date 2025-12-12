# PromptCraft - 开发指南

## 文档信息

- **项目名称**: PromptCraft
- **文档版本**: v1.0
- **创建日期**: 2025-12-02
- **最后更新**: 2025-12-02

---

## 目录

1. [开发环境搭建](#1-开发环境搭建)
2. [项目结构](#2-项目结构)
3. [开发流程](#3-开发流程)
4. [代码规范](#4-代码规范)
5. [调试技巧](#5-调试技巧)
6. [测试指南](#6-测试指南)
7. [常见问题](#7-常见问题)
8. [贡献指南](#8-贡献指南)

---

## 1. 开发环境搭建

### 1.1 系统要求

```
操作系统: macOS 13.0 (Ventura) 或更高
Xcode: 15.0 或更高
Swift: 5.9 或更高
```

### 1.2 安装 Xcode

```bash
# 从 App Store 安装 Xcode
# 或使用命令行工具
xcode-select --install

# 验证安装
xcode-select -p
swift --version
```

### 1.3 克隆项目

```bash
# 克隆仓库
git clone https://github.com/your-org/promptcraft.git
cd promptcraft

# 查看分支
git branch -a

# 切换到开发分支
git checkout develop
```

### 1.4 安装依赖

```bash
# 打开项目
open PromptCraft.xcodeproj

# Xcode 会自动解析并下载依赖
# 或手动解析: File > Packages > Resolve Package Versions
```

### 1.5 配置开发环境

创建 `Config.swift`:
```swift
enum Config {
    #if DEBUG
    static let apiBaseURL = "https://api.openai.com/v1"
    static let enableLogging = true
    #else
    static let apiBaseURL = "https://api.openai.com/v1"
    static let enableLogging = false
    #endif
}
```

### 1.6 安装开发工具

```bash
# 安装 SwiftLint
brew install swiftlint

# 安装 SwiftFormat
brew install swiftformat

# 验证安装
swiftlint version
swiftformat --version
```

---

## 2. 项目结构

### 2.1 目录结构

```
PromptCraft/
├── App/                    # 应用入口
├── Core/                   # 核心模块
│   ├── Models/            # 数据模型
│   ├── Services/          # 业务服务
│   └── Utils/             # 工具类
├── Features/              # 功能模块
│   ├── Optimize/          # 提示词优化
│   ├── Library/           # 提示词本
│   ├── MenuBar/           # 菜单栏
│   └── Settings/          # 设置
├── Shared/                # 共享组件
│   ├── Components/        # UI 组件
│   └── Styles/            # 样式
└── Resources/             # 资源文件
```

---

## 3. 开发流程

### 3.1 Git 工作流

#### 分支策略

```
main (生产)
  └── develop (开发)
      ├── feature/功能名
      ├── bugfix/问题描述
      └── hotfix/紧急修复
```

#### 创建功能分支

```bash
git checkout develop
git pull origin develop
git checkout -b feature/add-export
```

#### 提交代码

```bash
git add .
git commit -m "feat: 添加导出功能"
git push origin feature/add-export
```

### 3.2 提交信息规范

```
<type>: <subject>

<body>

<footer>
```

**类型**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建

**示例**:
```
feat(optimize): 添加流式输出

- 实现 SSE 解析
- 更新 UI
- 添加测试

Closes #123
```

---

## 4. 代码规范

### 4.1 命名规范

```swift
// 类型: PascalCase
class OptimizeViewModel { }

// 变量/函数: camelCase
var inputText: String
func optimize() { }

// 常量: camelCase
let maxRetries = 3

// 协议: 名词或形容词
protocol AIServiceProtocol { }
```

### 4.2 代码组织

```swift
class ViewModel: ObservableObject {
    // MARK: - Properties
    @Published var text = ""
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Public Methods
    func doSomething() { }
    
    // MARK: - Private Methods
    private func helper() { }
}
```

### 4.3 SwiftUI 规范

```swift
struct MyView: View {
    // MARK: - Properties
    @State private var text = ""
    
    // MARK: - Body
    var body: some View {
        VStack {
            headerSection
            contentSection
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        Text("Header")
    }
}
```

---

## 5. 调试技巧

### 5.1 日志系统

```swift
import OSLog

let logger = Logger(subsystem: "com.promptcraft", category: "network")

logger.debug("调试信息")
logger.info("普通信息")
logger.warning("警告")
logger.error("错误: \(error)")
```

### 5.2 断点调试

```swift
// LLDB 命令
po object           // 打印对象
p value            // 打印值
expr var = "new"   // 修改值
```

### 5.3 网络调试

```swift
#if DEBUG
print("URL: \(request.url)")
print("Headers: \(request.allHTTPHeaderFields)")
#endif
```

---

## 6. 测试指南

### 6.1 单元测试

```swift
import XCTest
@testable import PromptCraft

class ViewModelTests: XCTestCase {
    var viewModel: OptimizeViewModel!
    var mockService: MockAIService!
    
    override func setUp() {
        super.setUp()
        mockService = MockAIService()
        viewModel = OptimizeViewModel(aiService: mockService)
    }
    
    func testOptimize() async throws {
        // Given
        viewModel.inputText = "test"
        mockService.mockResponse = "result"
        
        // When
        await viewModel.optimize()
        
        // Then
        XCTAssertEqual(viewModel.optimizedText, "result")
    }
}
```

### 6.2 UI 测试

```swift
class UITests: XCTestCase {
    let app = XCUIApplication()
    
    func testOptimizeFlow() {
        app.launch()
        
        let textField = app.textFields["inputField"]
        textField.tap()
        textField.typeText("帮我写文章")
        
        app.buttons["optimizeButton"].tap()
        
        XCTAssertTrue(app.staticTexts["result"].exists)
    }
}
```

### 6.3 运行测试

```bash
# 运行所有测试
⌘U

# 运行单个测试
点击测试方法旁的菱形图标

# 命令行运行
xcodebuild test -scheme PromptCraft
```

---

## 7. 常见问题

### Q1: SwiftData 迁移失败

**问题**: 数据模型变更后应用崩溃

**解决**:
```swift
// 创建迁移计划
let schema = Schema([Prompt.self])
let config = ModelConfiguration(
    schema: schema,
    migrationPlan: MyMigrationPlan.self
)
```

### Q2: 快捷键不响应

**问题**: 全局快捷键无法触发

**解决**:
```swift
// 检查辅助功能权限
let trusted = AXIsProcessTrusted()
if !trusted {
    // 提示用户授权
}
```

### Q3: API 调用超时

**问题**: OpenAI API 请求超时

**解决**:
```swift
// 增加超时时间
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 60
```

### Q4: 内存泄漏

**问题**: ViewModel 未释放

**解决**:
```swift
// 使用 weak self
Task { [weak self] in
    await self?.doSomething()
}
```

---

## 8. 贡献指南

### 8.1 如何贡献

1. Fork 项目
2. 创建功能分支
3. 提交代码
4. 创建 Pull Request

### 8.2 PR 检查清单

- [ ] 代码通过 SwiftLint 检查
- [ ] 添加了单元测试
- [ ] 更新了文档
- [ ] 通过了 CI 测试
- [ ] 代码已审查

### 8.3 代码审查标准

- 代码清晰易读
- 遵循项目规范
- 测试覆盖充分
- 性能无明显问题
- 无安全隐患

---

## 附录

### A. 快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘R | 运行 |
| ⌘B | 构建 |
| ⌘U | 测试 |
| ⌘. | 停止 |
| ⌘K | 清理 |
| ⌘⇧K | 清理构建文件夹 |

### B. 有用的链接

- [Swift 官方文档](https://swift.org/documentation/)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [macOS HIG](https://developer.apple.com/design/human-interface-guidelines/macos)

---

*文档版本: v1.0*
*创建日期: 2025-12-02*
*维护者: 开发团队*
