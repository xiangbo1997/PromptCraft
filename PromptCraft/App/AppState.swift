import SwiftUI
import Observation

// MARK: - 主窗口标签页
enum MainTab: String, CaseIterable, Identifiable {
    case scenes      // 场景库（首页）
    case optimize
    case library
    case tags
    case settings
    case history
    case favorites

    var id: String { rawValue }

    /// 本地化显示名称（必须在主线程调用）
    @MainActor
    var localizedName: String {
        let l = LocalizationService.shared
        switch self {
        case .scenes: return "场景库"
        case .optimize: return l.l("tab.optimize")
        case .library: return l.l("tab.library")
        case .tags: return l.l("tab.tags")
        case .settings: return l.l("tab.settings")
        case .history: return l.l("tab.history")
        case .favorites: return l.l("tab.favorites")
        }
    }

    var icon: String {
        switch self {
        case .scenes: return "square.grid.2x2"
        case .optimize: return "wand.and.stars"
        case .library: return "books.vertical"
        case .tags: return "tag"
        case .settings: return "gearshape"
        case .history: return "clock"
        case .favorites: return "star"
        }
    }
}

@MainActor
@Observable
class AppState {
    var theme: Theme = .system
    var aiService: AIServiceProtocol
    var storageService: StorageService
    var clipboardService: ClipboardService
    var hotkeyService: HotkeyService
    var showCopyToast: Bool = true // 是否显示复制成功提示
    var apiServiceManager: APIServiceManager

    // 导航状态 - 用于从菜单栏控制主窗口
    var selectedTab: MainTab? = .scenes
    var shouldOpenMainWindow: Bool = false

    // UserDefaults key for API Key (与 SettingsViewModel 保持一致)
    private static let apiKeyStorageKey = "api_key"

    init() {
        // 先创建服务实例
        let storage = StorageService()
        let clipboard = ClipboardService()
        let hotkey = HotkeyService()
        let apiManager = APIServiceManager.shared

        // 从 AppSettings 读取主题等配置
        var loadedTheme: Theme = .system
        var loadedShowCopyToast: Bool = true

        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            loadedTheme = settings.theme
            loadedShowCopyToast = settings.showCopyToast
        }

        // 一次性赋值所有存储属性
        self.storageService = storage
        self.clipboardService = clipboard
        self.hotkeyService = hotkey
        self.apiServiceManager = apiManager
        self.theme = loadedTheme
        self.showCopyToast = loadedShowCopyToast

        // 根据 API 服务模式获取对应的 AI 服务
        self.aiService = apiManager.getAIService()

        print("[AppState] API Mode: \(apiManager.currentMode.displayName)")
        print("[AppState] Theme: \(loadedTheme.rawValue)")
    }

    func updateSettings() {
        // 重新获取 AI 服务
        self.aiService = apiServiceManager.getAIService()
        print("[AppState] Updated AI Service, Mode: \(apiServiceManager.currentMode.displayName)")
    }

    func updateAPIKey(_ key: String) {
        // 保存到 UserDefaults
        if key.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.apiKeyStorageKey)
        } else {
            UserDefaults.standard.set(key, forKey: Self.apiKeyStorageKey)
        }
        // 更新自定义 API Key
        apiServiceManager.setCustomAPIKey(key)
        // 更新 AI 服务
        updateSettings()
    }

    /// 切换 API 服务模式
    func setAPIMode(_ mode: APIServiceMode) {
        apiServiceManager.setMode(mode)
        updateSettings()
    }

    /// 打开主窗口并导航到指定标签页
    func navigateToTab(_ tab: MainTab) {
        selectedTab = tab
        shouldOpenMainWindow = true
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("SparkPrompt") || $0.isKeyWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    /// 打开主窗口
    func openMainWindow() {
        shouldOpenMainWindow = true
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("SparkPrompt") || $0.isKeyWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// 主题枚举
enum Theme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    /// 本地化键名（用于视图层本地化）
    var localizationKey: String {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    /// 本地化显示名称（必须在主线程调用）
    @MainActor
    var localizedName: String {
        return LocalizationService.shared.l(localizationKey)
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
