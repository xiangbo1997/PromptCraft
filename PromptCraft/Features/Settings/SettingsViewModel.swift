import Foundation
import SwiftUI
import Observation
import ServiceManagement

// Represents the application-wide settings, stored in UserDefaults.
struct AppSettings: Codable {
    var theme: Theme = .system
    var language: AppLanguage = .system
    var defaultOptimizeMode: OptimizeMode = .detailed
    var launchAtLogin: Bool = false
    var showCopyToast: Bool = true
    var selectedModelId: String = AIModel.gpt4.id // Store only the ID
    var customAPIEndpoint: String? = nil
    var apiTimeout: TimeInterval = 30
    var maxRetries: Int = 3
    var dailyCallLimit: Int? = nil

    // Static key for UserDefaults
    static let storageKey = "app_settings"
}



/// ViewModel for managing application settings, including AI service configuration, hotkeys, and UI preferences.
@MainActor
@Observable
class SettingsViewModel {
    // Dependencies
    private let aiService: AIServiceProtocol
    private let hotkeyService: HotkeyService

    // UserDefaults key for API Key
    private static let apiKeyStorageKey = "api_key" 
    
    // Published properties for UI binding
    var apiKey: String = ""
    var selectedModel: AIModel
    var availableModels: [AIModel] = []
    var customAPIEndpoint: String = ""
    var apiTimeout: TimeInterval = 30
    var maxRetries: Int = 3
    var dailyCallLimit: Int? = nil
    
    var theme: Theme = .system
    var language: AppLanguage = .system
    var launchAtLogin: Bool = false
    var showCopyToast: Bool = true
    var defaultOptimizeMode: OptimizeMode = .detailed
    
    var isAPIKeyValid: Bool = false
    var isLoadingModels: Bool = false
    var validationError: String? = nil
    
    // Hotkey settings (managed by HotkeyService, exposed here for UI)
        var togglePanelHotkey: KeyCombo
        var quickOptimizeHotkey: KeyCombo
        var openLibraryHotkey: KeyCombo
    
        init(aiService: AIServiceProtocol, hotkeyService: HotkeyService) {
            self.aiService = aiService
            self.hotkeyService = hotkeyService
            
            // Initialize hotkeys with values from HotkeyService (which will have loaded from UserDefaults or defaults)
            self.togglePanelHotkey = hotkeyService.togglePanelKeyCombo
            self.quickOptimizeHotkey = hotkeyService.quickOptimizeKeyCombo
            self.openLibraryHotkey = hotkeyService.openLibraryKeyCombo
            
            // Initialize selectedModel with a fallback before loading settings
            self.selectedModel = .gpt4
    
            loadSettings()
            fetchAvailableModels()
        }
        
        /// Loads all settings from UserDefaults.
        func loadSettings() {
            // Load API Key from UserDefaults
            self.apiKey = UserDefaults.standard.string(forKey: Self.apiKeyStorageKey) ?? ""
            // Validate API Key immediately if it exists
            if !self.apiKey.isEmpty {
                Task { await self.validateAPIKey(self.apiKey) }
            }
            
            // Load other settings from UserDefaults
            let defaults = UserDefaults.standard
            if let data = defaults.data(forKey: AppSettings.storageKey),
               let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                self.theme = settings.theme
                self.language = settings.language
                self.defaultOptimizeMode = settings.defaultOptimizeMode
                self.launchAtLogin = settings.launchAtLogin
                self.showCopyToast = settings.showCopyToast
                // Initialize selectedModel from loaded settings, or fallback to default
                // Ensure availableModels is populated before this line runs, or handle fallback more robustly.
                self.selectedModel = availableModels.first(where: { $0.id == settings.selectedModelId }) ?? .gpt4
                self.customAPIEndpoint = settings.customAPIEndpoint ?? ""
                self.apiTimeout = settings.apiTimeout
                self.maxRetries = settings.maxRetries
                self.dailyCallLimit = settings.dailyCallLimit
                // 同步语言设置到 LocalizationService
                LocalizationService.shared.currentLanguage = settings.language
            } else {
                // If no settings saved, use initial defaults and save them
                saveSettings()
            }
    
            // Hotkey settings are now managed internally by HotkeyService and exposed via its properties
            // So we just update our view model properties from HotkeyService directly.
            self.togglePanelHotkey = hotkeyService.togglePanelKeyCombo
            self.quickOptimizeHotkey = hotkeyService.quickOptimizeKeyCombo
            self.openLibraryHotkey = hotkeyService.openLibraryKeyCombo
        }    
    /// Saves all current settings to UserDefaults.
    /// - Parameter validateKey: 是否需要验证 API Key，默认为 false，仅在 API Key 变化时设为 true
    func saveSettings(validateKey: Bool = false) {
        // Save API Key to UserDefaults
        if apiKey.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.apiKeyStorageKey)
        } else {
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyStorageKey)
        }
        // 仅在明确需要时才验证 API Key，避免每次保存都触发验证导致卡顿
        if validateKey && !apiKey.isEmpty {
            Task { await self.validateAPIKey(self.apiKey) }
        }
        
        // Save other settings to UserDefaults
        let settings = AppSettings(
            theme: theme,
            language: language,
            defaultOptimizeMode: defaultOptimizeMode,
            launchAtLogin: launchAtLogin,
            showCopyToast: showCopyToast,
            selectedModelId: selectedModel.id,
            customAPIEndpoint: customAPIEndpoint.isEmpty ? nil : customAPIEndpoint,
            apiTimeout: apiTimeout,
            maxRetries: maxRetries,
            dailyCallLimit: dailyCallLimit
        )
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: AppSettings.storageKey)
        }

        // Save hotkey settings
        let hotkeys = HotkeySettings(
            togglePanel: togglePanelHotkey,
            quickOptimize: quickOptimizeHotkey,
            openLibrary: openLibraryHotkey
        )
        if let encoded = try? JSONEncoder().encode(hotkeys) {
            UserDefaults.standard.set(encoded, forKey: HotkeySettings.storageKey)
        }
        
        // Propagate changes to AppState, if needed (for example, if AppState holds a direct reference to AIService)
        // This part would typically be handled by observing settings changes or a dedicated event bus.
        // For now, assume AppState's updateSettings() will pick up the changes from UserDefaults.
    }
    
    /// Validates the current API key using the AI service.
    @MainActor
    func validateAPIKey(_ key: String) async {
        guard !key.isEmpty else {
            isAPIKeyValid = false
            validationError = "API Key cannot be empty."
            return
        }
        
        validationError = nil
        isLoadingModels = true
        defer { isLoadingModels = false }
        
        do {
            // Temporarily create an AIService instance with the provided key for validation
            // This avoids updating the global aiService in AppState until the key is confirmed valid
            let tempAIService = OpenAIService(apiKey: key, model: selectedModel, baseURL: customAPIEndpoint.isEmpty ? "https://api.openai.com/v1" : customAPIEndpoint, timeout: apiTimeout)
            
            let isValid = try await tempAIService.validateAPIKey(key)
            isAPIKeyValid = isValid
            if !isValid {
                validationError = "Invalid API Key. Please check your key and API endpoint."
            } else {
                validationError = nil
            }
        } catch let error as AIError {
            isAPIKeyValid = false
            validationError = error.localizedDescription
        } catch {
            isAPIKeyValid = false
            validationError = "An unexpected error occurred during validation: \(error.localizedDescription)"
        }
    }
    
    /// Fetches available AI models from the AI service.
    @MainActor
    func fetchAvailableModels() {
        // 如果没有 API Key，不尝试获取模型
        guard !apiKey.isEmpty else {
            self.availableModels = []
            isLoadingModels = false
            return
        }

        isLoadingModels = true
        Task {
            do {
                // 使用当前的 API Key 和 endpoint 创建临时服务来获取模型
                let baseURL = customAPIEndpoint.isEmpty ? "https://api.openai.com/v1" : customAPIEndpoint
                let tempService = OpenAIService(apiKey: apiKey, model: selectedModel, baseURL: baseURL, timeout: apiTimeout)

                let models = try await tempService.fetchModels()
                self.availableModels = models.sorted { $0.id < $1.id }
                // Ensure selectedModel is one of the available models, or default
                if let currentSelected = self.availableModels.first(where: { $0.id == self.selectedModel.id }) {
                    self.selectedModel = currentSelected
                } else if let defaultModel = self.availableModels.first(where: { $0.id == AIModel.gpt4.id }){
                    self.selectedModel = defaultModel
                } else if let firstModel = self.availableModels.first {
                    self.selectedModel = firstModel
                } else {
                    self.selectedModel = .gpt4 // Fallback to a known model if none fetched
                }
                validationError = nil
            } catch let error as AIError {
                validationError = "Failed to fetch models: \(error.localizedDescription)"
                self.availableModels = []
            } catch {
                validationError = "An unexpected error occurred while fetching models: \(error.localizedDescription)"
                self.availableModels = []
            }
            isLoadingModels = false
        }
    }
    
    // Method to reset settings to default values
    func resetSettings() {
        theme = .system
        language = .system
        defaultOptimizeMode = .detailed
        launchAtLogin = false
        showCopyToast = true
        selectedModel = .gpt4
        customAPIEndpoint = ""
        apiTimeout = 30
        maxRetries = 3
        dailyCallLimit = nil

        // Reset language in LocalizationService
        LocalizationService.shared.currentLanguage = .system

        // Reset hotkeys as well
        togglePanelHotkey = HotkeyService.defaultTogglePanelKeyCombo
        quickOptimizeHotkey = HotkeyService.defaultQuickOptimizeKeyCombo
        openLibraryHotkey = HotkeyService.defaultOpenLibraryKeyCombo

        // Clear API Key from UserDefaults
        UserDefaults.standard.removeObject(forKey: Self.apiKeyStorageKey)
        apiKey = ""
        isAPIKeyValid = false

        saveSettings()
        fetchAvailableModels() // Re-fetch models with potentially cleared API key
    }
}
