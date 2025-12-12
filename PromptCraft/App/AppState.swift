import SwiftUI
import Observation

@MainActor
@Observable
class AppState {
    var theme: Theme = .system
    var aiService: AIServiceProtocol
    var storageService: StorageService
    var clipboardService: ClipboardService
    var hotkeyService: HotkeyService
    var showCopyToast: Bool = true // 是否显示复制成功提示

    // UserDefaults key for API Key (与 SettingsViewModel 保持一致)
    private static let apiKeyStorageKey = "api_key"

    init() {
        // 先创建服务实例
        let storage = StorageService()
        let clipboard = ClipboardService()
        let hotkey = HotkeyService()

        // 从 UserDefaults 读取配置
        let apiKey = UserDefaults.standard.string(forKey: Self.apiKeyStorageKey) ?? ""

        // 从 AppSettings 读取模型和 endpoint（与 SettingsViewModel 保持一致）
        var modelId = AIModel.gpt4.id
        var baseURL = "https://api.openai.com/v1"
        var loadedTheme: Theme = .system
        var loadedShowCopyToast: Bool = true

        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            modelId = settings.selectedModelId
            baseURL = settings.customAPIEndpoint ?? "https://api.openai.com/v1"
            if baseURL.isEmpty { baseURL = "https://api.openai.com/v1" }
            loadedTheme = settings.theme
            loadedShowCopyToast = settings.showCopyToast
        }

        let model = AIModel(id: modelId)
        let ai = OpenAIService(apiKey: apiKey, model: model, baseURL: baseURL)

        // 一次性赋值所有存储属性
        self.storageService = storage
        self.clipboardService = clipboard
        self.hotkeyService = hotkey
        self.aiService = ai
        self.theme = loadedTheme
        self.showCopyToast = loadedShowCopyToast

        print("[AppState] Using OpenAIService with baseURL: \(baseURL)")
        print("[AppState] Theme: \(loadedTheme.rawValue)")
    }

    func updateSettings() {
        let apiKey = UserDefaults.standard.string(forKey: Self.apiKeyStorageKey) ?? ""

        // 从 AppSettings 读取模型和 endpoint（与 SettingsViewModel 保持一致）
        var modelId = AIModel.gpt4.id
        var baseURL = "https://api.openai.com/v1"

        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            modelId = settings.selectedModelId
            baseURL = settings.customAPIEndpoint ?? "https://api.openai.com/v1"
            if baseURL.isEmpty { baseURL = "https://api.openai.com/v1" }
        }

        let model = AIModel(id: modelId)
        self.aiService = OpenAIService(apiKey: apiKey, model: model, baseURL: baseURL)
        print("[AppState] Updated OpenAIService with baseURL: \(baseURL)")
    }

    func updateAPIKey(_ key: String) {
        // 保存到 UserDefaults
        if key.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.apiKeyStorageKey)
        } else {
            UserDefaults.standard.set(key, forKey: Self.apiKeyStorageKey)
        }
        // 更新 AI 服务
        updateSettings()
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
