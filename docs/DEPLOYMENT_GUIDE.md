# PromptCraft - 部署运维文档

## 文档信息

- **项目名称**: PromptCraft
- **文档版本**: v1.0
- **创建日期**: 2025-12-02
- **最后更新**: 2025-12-02

---

## 目录

1. [构建配置](#1-构建配置)
2. [代码签名](#2-代码签名)
3. [打包发布](#3-打包发布)
4. [应用公证](#4-应用公证)
5. [版本管理](#5-版本管理)
6. [自动更新](#6-自动更新)
7. [监控运维](#7-监控运维)
8. [故障排查](#8-故障排查)

---

## 1. 构建配置

### 1.1 构建环境

| 环境 | 用途 | 配置 |
|------|------|------|
| Debug | 开发调试 | 启用日志、调试符号 |
| Release | 生产发布 | 优化性能、禁用日志 |

### 1.2 配置文件

#### Debug 配置

```swift
// Config.swift
#if DEBUG
enum Config {
    static let apiBaseURL = "https://api.openai.com/v1"
    static let enableLogging = true
    static let enableAnalytics = false
    static let crashReportingEnabled = false
}
#endif
```

#### Release 配置

```swift
#if !DEBUG
enum Config {
    static let apiBaseURL = "https://api.openai.com/v1"
    static let enableLogging = false
    static let enableAnalytics = true
    static let crashReportingEnabled = true
}
#endif
```

### 1.3 编译优化

**Build Settings**:
```
Optimization Level:
  - Debug: -Onone (无优化)
  - Release: -O (优化速度)

Swift Compilation Mode:
  - Debug: Incremental (增量编译)
  - Release: Whole Module (整模块优化)

Strip Debug Symbols:
  - Debug: No
  - Release: Yes

Enable Bitcode:
  - No (macOS 不需要)
```

### 1.4 构建脚本

```bash
#!/bin/bash
# build.sh - 自动化构建脚本

set -e

# 配置
SCHEME="PromptCraft"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PromptCraft.xcarchive"
EXPORT_PATH="./build/export"

# 清理
echo "🧹 清理构建目录..."
rm -rf build
mkdir -p build

# 构建
echo "🔨 开始构建..."
xcodebuild clean \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION"

# Archive
echo "📦 创建 Archive..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH"

# Export
echo "📤 导出应用..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist

echo "✅ 构建完成！"
echo "📍 输出路径: $EXPORT_PATH"
```

**ExportOptions.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

---

## 2. 代码签名

### 2.1 证书配置

#### 开发证书
```
证书类型: Apple Development
用途: 本地开发和测试
有效期: 1 年
```

#### 发布证书
```
证书类型: Developer ID Application
用途: 在 App Store 外分发
有效期: 5 年
```

### 2.2 配置签名

**Xcode 配置**:
```
1. 选择 Target: PromptCraft
2. Signing & Capabilities
3. Team: 选择你的开发团队
4. Signing Certificate: Developer ID Application
5. Provisioning Profile: Automatic
```

### 2.3 手动签名

```bash
# 查看可用证书
security find-identity -v -p codesigning

# 签名应用
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --options runtime \
    --entitlements PromptCraft.entitlements \
    ./PromptCraft.app

# 验证签名
codesign --verify --deep --strict --verbose=2 ./PromptCraft.app
spctl --assess --type execute --verbose ./PromptCraft.app
```

### 2.4 Entitlements

**PromptCraft.entitlements**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 网络访问 -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- 用户选择的文件访问 -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- 辅助功能（快捷键） -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
</dict>
</plist>
```

---

## 3. 打包发布

### 3.1 创建 DMG

#### 方式 1: 使用 create-dmg

```bash
# 安装工具
brew install create-dmg

# 创建 DMG
create-dmg \
    --volname "PromptCraft" \
    --volicon "icon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "PromptCraft.app" 175 120 \
    --hide-extension "PromptCraft.app" \
    --app-drop-link 425 120 \
    "PromptCraft-1.0.0.dmg" \
    "build/export/"
```

#### 方式 2: 手动创建

```bash
# 创建临时文件夹
mkdir -p dmg-temp
cp -r "PromptCraft.app" dmg-temp/

# 创建 DMG
hdiutil create -volname "PromptCraft" \
    -srcfolder dmg-temp \
    -ov -format UDZO \
    "PromptCraft-1.0.0.dmg"

# 清理
rm -rf dmg-temp
```

### 3.2 DMG 自定义

创建 `.DS_Store` 自定义 DMG 外观：

```
1. 打开 DMG
2. 调整窗口大小和图标位置
3. 设置背景图片
4. 复制 .DS_Store 文件
5. 在构建脚本中使用
```

### 3.3 版本号管理

**Info.plist**:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

**自动更新版本号**:
```bash
#!/bin/bash
# bump-version.sh

VERSION_TYPE=$1  # major, minor, patch

# 读取当前版本
CURRENT_VERSION=$(agvtool what-marketing-version -terse1)

# 计算新版本
# ... (版本计算逻辑)

# 更新版本
agvtool new-marketing-version $NEW_VERSION
agvtool next-version -all
```

---

## 4. 应用公证

### 4.1 公证流程

应用公证（Notarization）是 macOS 的安全要求。

```bash
#!/bin/bash
# notarize.sh - 公证脚本

APP_PATH="./PromptCraft.app"
DMG_PATH="./PromptCraft-1.0.0.dmg"
BUNDLE_ID="com.promptcraft.app"
APPLE_ID="your@email.com"
TEAM_ID="YOUR_TEAM_ID"

# 1. 压缩应用
echo "📦 压缩应用..."
ditto -c -k --keepParent "$APP_PATH" "PromptCraft.zip"

# 2. 上传公证
echo "📤 上传公证..."
xcrun notarytool submit "PromptCraft.zip" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# 3. 装订公证票据
echo "🎫 装订票据..."
xcrun stapler staple "$APP_PATH"

# 4. 验证
echo "✅ 验证公证..."
spctl --assess --type execute --verbose "$APP_PATH"

# 5. 创建 DMG
echo "💿 创建 DMG..."
create-dmg "$DMG_PATH" "$APP_PATH"

# 6. 公证 DMG
echo "📤 公证 DMG..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# 7. 装订 DMG
echo "🎫 装订 DMG..."
xcrun stapler staple "$DMG_PATH"

echo "✅ 公证完成！"
```

### 4.2 存储密码

```bash
# 存储 App-Specific Password 到 Keychain
xcrun notarytool store-credentials "AC_PASSWORD" \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"
```

### 4.3 检查公证状态

```bash
# 查看公证历史
xcrun notarytool history \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"

# 查看公证详情
xcrun notarytool info SUBMISSION_ID \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"

# 查看公证日志
xcrun notarytool log SUBMISSION_ID \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"
```

---

## 5. 版本管理

### 5.1 版本号规则

使用 [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

MAJOR: 不兼容的 API 变更
MINOR: 向后兼容的功能新增
PATCH: 向后兼容的问题修复

示例:
1.0.0 - 首个正式版本
1.1.0 - 添加流式输出功能
1.1.1 - 修复搜索 bug
2.0.0 - 重大架构升级
```

### 5.2 版本发布流程

```bash
# 1. 更新版本号
./scripts/bump-version.sh minor

# 2. 更新 CHANGELOG
vim CHANGELOG.md

# 3. 提交版本变更
git add .
git commit -m "chore: bump version to 1.1.0"

# 4. 创建标签
git tag -a v1.1.0 -m "Release v1.1.0"

# 5. 推送到远程
git push origin develop
git push origin v1.1.0

# 6. 构建发布版本
./scripts/build.sh

# 7. 公证应用
./scripts/notarize.sh

# 8. 上传到分发渠道
./scripts/upload.sh
```

### 5.3 CHANGELOG 格式

```markdown
# Changelog

## [1.1.0] - 2025-12-15

### Added
- 流式输出支持
- 导出数据功能
- 预置提示词模板

### Changed
- 优化搜索性能
- 改进 UI 响应速度

### Fixed
- 修复搜索崩溃问题
- 修复快捷键冲突

## [1.0.0] - 2025-12-01

### Added
- 初始版本发布
- 提示词优化功能
- 提示词本管理
- 菜单栏快捷访问
```

---

## 6. 自动更新

### 6.1 集成 Sparkle

**Package.swift**:
```swift
dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0")
]
```

**配置 Sparkle**:
```swift
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}
```

### 6.2 生成 Appcast

```bash
# 安装 generate_appcast
brew install sparkle

# 生成 appcast.xml
generate_appcast \
    --ed-key-file dsa_priv.pem \
    --download-url-prefix https://releases.promptcraft.app/ \
    ./releases/
```

**appcast.xml**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>PromptCraft Updates</title>
        <link>https://releases.promptcraft.app/appcast.xml</link>
        <description>PromptCraft 更新</description>
        <language>zh-CN</language>
        
        <item>
            <title>Version 1.1.0</title>
            <sparkle:releaseNotesLink>
                https://releases.promptcraft.app/notes/1.1.0.html
            </sparkle:releaseNotesLink>
            <pubDate>Mon, 15 Dec 2025 10:00:00 +0800</pubDate>
            <enclosure 
                url="https://releases.promptcraft.app/PromptCraft-1.1.0.dmg"
                sparkle:version="1.1.0"
                sparkle:shortVersionString="1.1.0"
                length="15728640"
                type="application/octet-stream"
                sparkle:edSignature="..." />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
```

### 6.3 发布更新

```bash
#!/bin/bash
# release.sh - 发布更新

VERSION=$1
DMG_FILE="PromptCraft-${VERSION}.dmg"
RELEASES_DIR="./releases"
APPCAST_FILE="${RELEASES_DIR}/appcast.xml"

# 1. 复制 DMG 到发布目录
cp "build/${DMG_FILE}" "${RELEASES_DIR}/"

# 2. 生成 appcast
generate_appcast \
    --ed-key-file dsa_priv.pem \
    --download-url-prefix https://releases.promptcraft.app/ \
    "${RELEASES_DIR}"

# 3. 上传到服务器
rsync -avz "${RELEASES_DIR}/" user@server:/var/www/releases/

echo "✅ 发布完成！"
```

---

## 7. 监控运维

### 7.1 错误日志收集

```swift
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let logFileURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let logDir = appSupport.appendingPathComponent("PromptCraft/Logs")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "error-\(dateFormatter.string(from: Date())).log"
        
        logFileURL = logDir.appendingPathComponent(filename)
    }
    
    func log(_ error: Error, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let message = """
        [\(timestamp)] ERROR
        Context: \(context)
        Error: \(error.localizedDescription)
        ---
        
        """
        
        if let data = message.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}
```

### 7.2 性能监控

```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    func trackAPICall(duration: TimeInterval, success: Bool) {
        let metrics: [String: Any] = [
            "type": "api_call",
            "duration": duration,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 记录到本地或发送到分析服务
        saveMetrics(metrics)
    }
    
    func trackAppLaunch(duration: TimeInterval) {
        let metrics: [String: Any] = [
            "type": "app_launch",
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        saveMetrics(metrics)
    }
    
    private func saveMetrics(_ metrics: [String: Any]) {
        // 保存到本地数据库或发送到服务器
    }
}
```

### 7.3 使用统计

```swift
class AnalyticsService {
    static let shared = AnalyticsService()
    
    func trackEvent(_ event: String, properties: [String: Any] = [:]) {
        #if !DEBUG
        let eventData: [String: Any] = [
            "event": event,
            "properties": properties,
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        // 发送到分析服务（可选）
        // 或保存到本地
        saveEvent(eventData)
        #endif
    }
    
    private func saveEvent(_ event: [String: Any]) {
        // 实现本地存储
    }
}
```

---

## 8. 故障排查

### 8.1 常见问题

#### 问题 1: 应用无法启动

**症状**: 双击应用无响应

**排查步骤**:
```bash
# 1. 检查崩溃日志
open ~/Library/Logs/DiagnosticReports/

# 2. 检查控制台日志
log show --predicate 'process == "PromptCraft"' --last 1h

# 3. 检查签名
codesign --verify --deep --strict --verbose=2 /Applications/PromptCraft.app
```

#### 问题 2: 公证失败

**症状**: 公证提交被拒绝

**排查步骤**:
```bash
# 查看公证日志
xcrun notarytool log SUBMISSION_ID \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"

# 常见原因:
# - 未启用 Hardened Runtime
# - Entitlements 配置错误
# - 包含未签名的二进制文件
```

#### 问题 3: 更新失败

**症状**: Sparkle 无法检测更新

**排查步骤**:
```bash
# 1. 验证 appcast.xml 可访问
curl https://releases.promptcraft.app/appcast.xml

# 2. 检查 appcast 格式
xmllint --noout appcast.xml

# 3. 验证签名
# 确保 DMG 已正确签名
```

### 8.2 日志收集

```bash
# 收集诊断信息
#!/bin/bash
# collect-diagnostics.sh

OUTPUT_DIR="./diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 1. 应用日志
cp -r ~/Library/Logs/PromptCraft "$OUTPUT_DIR/app-logs"

# 2. 崩溃报告
cp ~/Library/Logs/DiagnosticReports/PromptCraft* "$OUTPUT_DIR/crash-reports"

# 3. 系统信息
system_profiler SPSoftwareDataType > "$OUTPUT_DIR/system-info.txt"

# 4. 控制台日志
log show --predicate 'process == "PromptCraft"' --last 1h > "$OUTPUT_DIR/console.log"

# 5. 压缩
zip -r "diagnostics.zip" "$OUTPUT_DIR"

echo "✅ 诊断信息已收集到 diagnostics.zip"
```

### 8.3 性能分析

```bash
# 使用 Instruments 分析
instruments -t "Time Profiler" -D trace.trace PromptCraft.app

# 分析内存泄漏
instruments -t "Leaks" -D leaks.trace PromptCraft.app

# 分析网络请求
instruments -t "Network" -D network.trace PromptCraft.app
```

---

## 附录

### A. CI/CD 配置

**GitHub Actions**:
```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-13
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'
      
      - name: Build
        run: |
          xcodebuild archive \
            -scheme PromptCraft \
            -archivePath build/PromptCraft.xcarchive
      
      - name: Export
        run: |
          xcodebuild -exportArchive \
            -archivePath build/PromptCraft.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ExportOptions.plist
      
      - name: Create DMG
        run: |
          create-dmg \
            --volname "PromptCraft" \
            "PromptCraft-${{ github.ref_name }}.dmg" \
            build/export/
      
      - name: Release
        uses: softprops/action-gh-release@v1
        with:
          files: PromptCraft-*.dmg
```

### B. 发布检查清单

- [ ] 更新版本号
- [ ] 更新 CHANGELOG
- [ ] 运行所有测试
- [ ] 代码审查通过
- [ ] 构建 Release 版本
- [ ] 代码签名
- [ ] 应用公证
- [ ] 创建 DMG
- [ ] 更新 appcast.xml
- [ ] 上传到服务器
- [ ] 创建 GitHub Release
- [ ] 更新文档
- [ ] 通知用户

### C. 有用的命令

```bash
# 查看应用信息
mdls -name kMDItemVersion /Applications/PromptCraft.app

# 查看签名信息
codesign -dv --verbose=4 /Applications/PromptCraft.app

# 查看 Entitlements
codesign -d --entitlements :- /Applications/PromptCraft.app

# 验证公证
spctl --assess --verbose /Applications/PromptCraft.app

# 查看应用大小
du -sh /Applications/PromptCraft.app
```

---

*文档版本: v1.0*
*创建日期: 2025-12-02*
*维护者: 运维团队*
