import Foundation
import SwiftUI

// MARK: - 支持的语言枚举

/// 应用支持的语言
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system = "system"      // 跟随系统
    case english = "en"         // English
    case chinese = "zh-Hans"    // 简体中文

    var id: String { rawValue }

    /// 显示名称（需在主线程调用）
    @MainActor
    var displayName: String {
        switch self {
        case .system: return LocalizationService.shared.localizedString("language.system")
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    /// 用于显示的本地名称（不受当前语言影响）
    var nativeName: String {
        switch self {
        case .system: return "🌐 Auto"
        case .english: return "🇺🇸 English"
        case .chinese: return "🇨🇳 简体中文"
        }
    }
}

// MARK: - 本地化管理服务

/// 本地化服务单例，管理应用语言切换
/// 使用 @Observable 支持 SwiftUI 视图自动响应语言变化
/// @MainActor 确保所有访问都在主线程进行，避免 SwiftData 线程冲突
@MainActor
@Observable
final class LocalizationService {
    static let shared = LocalizationService()

    /// 当前选择的语言（变化时触发视图更新）
    var currentLanguage: AppLanguage {
        didSet {
            saveLanguagePreference()
            updateBundle()
            // 增加更新计数器，强制依赖此服务的视图刷新
            refreshTrigger += 1
        }
    }

    /// 用于触发视图刷新的计数器
    /// 视图可以通过监听此属性来响应语言变化
    private(set) var refreshTrigger: Int = 0

    /// 当前使用的本地化 Bundle
    private(set) var bundle: Bundle = .main

    private let languageKey = "app_language"

    private init() {
        // 从 UserDefaults 加载保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        updateBundle()
    }

    /// 保存语言偏好到 UserDefaults
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// 更新本地化 Bundle
    private func updateBundle() {
        let languageCode: String

        switch currentLanguage {
        case .system:
            // 获取系统首选语言
            languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        case .english:
            languageCode = "en"
        case .chinese:
            languageCode = "zh-Hans"
        }

        // 尝试加载对应语言的 bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let bundle = Bundle(path: path) {
            // 回退到英文
            self.bundle = bundle
        } else {
            self.bundle = .main
        }
    }

    /// 获取本地化字符串
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// 获取带参数的本地化字符串
    func localizedString(_ key: String, arguments: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, arguments: arguments)
    }

    /// 实际使用的语言代码
    var effectiveLanguageCode: String {
        switch currentLanguage {
        case .system:
            return Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        case .english:
            return "en"
        case .chinese:
            return "zh-Hans"
        }
    }

    /// 便捷方法：获取本地化字符串（简写）
    func l(_ key: String) -> String {
        return localizedString(key)
    }
}

// MARK: - 便捷本地化扩展

extension String {
    /// 本地化字符串（需在主线程调用）
    @MainActor
    var localized: String {
        return LocalizationService.shared.localizedString(self)
    }

    /// 带参数的本地化字符串（需在主线程调用）
    @MainActor
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationService.shared.localizedString(self)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - SwiftUI Text 扩展

extension Text {
    /// 创建本地化 Text（需在主线程调用）
    @MainActor
    init(localized key: String) {
        self.init(LocalizationService.shared.localizedString(key))
    }
}

// MARK: - 本地化字符串键常量

/// 本地化字符串键
enum L10n {
    // MARK: - 通用
    enum Common {
        static let appName = "app.name"
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let copy = "common.copy"
        static let copied = "common.copied"
        static let search = "common.search"
        static let loading = "common.loading"
        static let error = "common.error"
        static let success = "common.success"
        static let warning = "common.warning"
    }

    // MARK: - 导航标签
    enum Tab {
        static let optimize = "tab.optimize"
        static let library = "tab.library"
        static let tags = "tab.tags"
        static let settings = "tab.settings"
        static let history = "tab.history"
        static let favorites = "tab.favorites"
    }

    // MARK: - 优化页面
    enum Optimize {
        static let title = "optimize.title"
        static let inputPlaceholder = "optimize.input.placeholder"
        static let outputPlaceholder = "optimize.output.placeholder"
        static let optimizeButton = "optimize.button"
        static let modeLabel = "optimize.mode.label"
        static let modeConcise = "optimize.mode.concise"
        static let modeDetailed = "optimize.mode.detailed"
        static let modeProfessional = "optimize.mode.professional"
    }

    // MARK: - 设置页面
    enum Settings {
        static let title = "settings.title"
        static let aiConfig = "settings.ai.config"
        static let apiKey = "settings.api.key"
        static let apiKeyPlaceholder = "settings.api.key.placeholder"
        static let apiKeyValid = "settings.api.key.valid"
        static let apiKeyInvalid = "settings.api.key.invalid"
        static let validateButton = "settings.validate.button"
        static let model = "settings.model"
        static let customEndpoint = "settings.custom.endpoint"
        static let timeout = "settings.timeout"
        static let maxRetries = "settings.max.retries"
        static let dailyLimit = "settings.daily.limit"

        static let hotkeys = "settings.hotkeys"
        static let togglePanel = "settings.hotkey.toggle.panel"
        static let quickOptimize = "settings.hotkey.quick.optimize"
        static let openLibrary = "settings.hotkey.open.library"

        static let appearance = "settings.appearance"
        static let theme = "settings.theme"
        static let language = "settings.language"

        static let general = "settings.general"
        static let launchAtLogin = "settings.launch.at.login"
        static let defaultMode = "settings.default.mode"
        static let showToast = "settings.show.toast"

        static let dataManagement = "settings.data.management"
        static let exportData = "settings.export.data"
        static let importData = "settings.import.data"
        static let clearData = "settings.clear.data"

        static let about = "settings.about"
        static let version = "settings.version"
        static let checkUpdate = "settings.check.update"
        static let resetSettings = "settings.reset"
    }

    // MARK: - 库页面
    enum Library {
        static let title = "library.title"
        static let emptyMessage = "library.empty.message"
        static let searchPlaceholder = "library.search.placeholder"
        static let sortBy = "library.sort.by"
        static let filterByCategory = "library.filter.category"
        static let filterByTag = "library.filter.tag"
    }

    // MARK: - 历史页面
    enum History {
        static let title = "history.title"
        static let emptyMessage = "history.empty.message"
        static let clearAll = "history.clear.all"
    }

    // MARK: - 收藏页面
    enum Favorites {
        static let title = "favorites.title"
        static let emptyMessage = "favorites.empty.message"
        static let addToFavorites = "favorites.add"
        static let removeFromFavorites = "favorites.remove"
    }

    // MARK: - 标签分类页面
    enum TagsCategories {
        static let title = "tags.title"
        static let categories = "tags.categories"
        static let tags = "tags.tags"
        static let addCategory = "tags.add.category"
        static let addTag = "tags.add.tag"
        static let emptyCategories = "tags.empty.categories"
        static let emptyTags = "tags.empty.tags"
    }

    // MARK: - 语言
    enum Language {
        static let system = "language.system"
        static let english = "language.english"
        static let chinese = "language.chinese"
    }

    // MARK: - 主题
    enum Theme {
        static let system = "theme.system"
        static let light = "theme.light"
        static let dark = "theme.dark"
    }

    // MARK: - MenuBar
    enum MenuBar {
        static let optimize = "menubar.optimize"
        static let recent = "menubar.recent"
        static let favorites = "menubar.favorites"
        static let openMain = "menubar.open.main"
        static let preferences = "menubar.preferences"
        static let quit = "menubar.quit"
    }
}
