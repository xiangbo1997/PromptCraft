import SwiftUI
import ServiceManagement // For SMAppService
import KeyboardShortcuts // For hotkey recording

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) private var modelContext // Inject modelContext for data operations

    // SettingsViewModel is now initialized with dependencies from AppState
    @State private var viewModel: SettingsViewModel
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    // Use initializer to inject dependencies for the StateObject
    init(aiService: AIServiceProtocol, hotkeyService: HotkeyService) {
        _viewModel = State(initialValue: SettingsViewModel(
            aiService: aiService,
            hotkeyService: hotkeyService
        ))
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    var body: some View {
        Form {
            // MARK: - AI Service Configuration
            Section(localization.l("settings.ai.config")) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(localization.l("settings.api.key"))
                        .font(.bodyRegular)

                    SecureField("sk-...", text: $viewModel.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.apiKey) { oldValue, newValue in
                            viewModel.saveSettings(validateKey: true)
                            // Propagate API key change to AppState to update AIService immediately
                            appState.updateAPIKey(newValue)
                        }

                    if viewModel.isLoadingModels {
                        ProgressView(localization.l("common.loading"))
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .padding(.vertical, Spacing.xs)
                    } else {
                        HStack {
                            if viewModel.isAPIKeyValid && !viewModel.apiKey.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.success)
                                Text(localization.l("settings.api.key.valid"))
                                    .font(.bodySmall)
                                    .foregroundColor(Color.success)
                            } else if !viewModel.apiKey.isEmpty {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.error)
                                Text(viewModel.validationError ?? localization.l("settings.api.key.invalid"))
                                    .font(.bodySmall)
                                    .foregroundColor(Color.error)
                            }
                            Spacer()
                            Button(localization.l("settings.validate.button")) {
                                Task { await viewModel.validateAPIKey(viewModel.apiKey) }
                                viewModel.fetchAvailableModels()
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }

                Picker(localization.l("settings.model"), selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels, id: \.id) { model in
                        Text(model.id).tag(model)
                    }
                }
                .onChange(of: viewModel.selectedModel) { _, newValue in
                    viewModel.saveSettings()
                    appState.updateSettings()
                }

                TextField(localization.l("settings.custom.endpoint"), text: $viewModel.customAPIEndpoint)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.customAPIEndpoint) { _, _ in
                        viewModel.saveSettings(validateKey: true)
                        appState.updateSettings()
                    }

                HStack {
                    Text(localization.l("settings.timeout"))
                    Spacer()
                    Picker("", selection: $viewModel.apiTimeout) {
                        Text("15 Seconds").tag(15.0)
                        Text("30 Seconds").tag(30.0)
                        Text("60 Seconds").tag(60.0)
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                    .onChange(of: viewModel.apiTimeout) { _, _ in
                        viewModel.saveSettings()
                        appState.updateSettings()
                    }
                }

                Stepper("\(localization.l("settings.max.retries")): \(viewModel.maxRetries)", value: $viewModel.maxRetries, in: 0...5)
                    .onChange(of: viewModel.maxRetries) { _, _ in
                        viewModel.saveSettings()
                        appState.updateSettings()
                    }

                HStack {
                    Text(localization.l("settings.daily.limit"))
                    Spacer()
                    TextField("None", value: $viewModel.dailyCallLimit, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: viewModel.dailyCallLimit) { _, _ in
                            viewModel.saveSettings()
                        }
                }
            }

            // MARK: - Hotkey Settings
            Section(localization.l("settings.hotkeys")) {
                // The KeyboardShortcuts.Recorder directly updates the KeyboardShortcuts.Name it's bound to.
                // We need to map our KeyCombo to KeyboardShortcuts.Name for the Recorder.
                // Then, in the onChange, we update our ViewModel's KeyCombo property and HotkeyService.

                HotkeyRecorder(label: localization.l("settings.hotkey.toggle.panel"), shortcut: $viewModel.togglePanelHotkey, hotkeyName: .togglePanel)
                    .onChange(of: viewModel.togglePanelHotkey) { _, newValue in
                        viewModel.saveSettings()
                        appState.hotkeyService.setShortcut(newValue, for: .togglePanel)
                    }
                HotkeyRecorder(label: localization.l("settings.hotkey.quick.optimize"), shortcut: $viewModel.quickOptimizeHotkey, hotkeyName: .quickOptimize)
                    .onChange(of: viewModel.quickOptimizeHotkey) { _, newValue in
                        viewModel.saveSettings()
                        appState.hotkeyService.setShortcut(newValue, for: .quickOptimize)
                    }
                HotkeyRecorder(label: localization.l("settings.hotkey.open.library"), shortcut: $viewModel.openLibraryHotkey, hotkeyName: .openLibrary)
                    .onChange(of: viewModel.openLibraryHotkey) { _, newValue in
                        viewModel.saveSettings()
                        appState.hotkeyService.setShortcut(newValue, for: .openLibrary)
                    }
            }

            // MARK: - Appearance
            Section(localization.l("settings.appearance")) {
                Picker(localization.l("settings.theme"), selection: $viewModel.theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.localizedName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.theme) { _, newValue in
                    viewModel.saveSettings()
                    // 只更新 AppStorage，不触发 appState.theme
                    UserDefaults.standard.set(newValue.rawValue, forKey: "app_theme")
                }

                Picker(localization.l("settings.language"), selection: $viewModel.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.language) { _, newValue in
                    viewModel.saveSettings()
                    // 更新 LocalizationService
                    LocalizationService.shared.currentLanguage = newValue
                }
            }

            // MARK: - General
            Section(localization.l("settings.general")) {
                Toggle(localization.l("settings.launch.at.login"), isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { _, newValue in
                        viewModel.saveSettings()
                        if newValue {
                            if SMAppService.mainApp.status == .enabled {
                                print("Login item already enabled.")
                            } else {
                                do {
                                    try SMAppService.mainApp.register()
                                    print("Login item registered.")
                                } catch {
                                    print("Failed to register login item: \(error.localizedDescription)")
                                    // Optionally, revert toggle state if registration fails
                                    viewModel.launchAtLogin = false
                                }
                            }
                        } else {
                            if SMAppService.mainApp.status == .enabled {
                                do {
                                    try SMAppService.mainApp.unregister()
                                    print("Login item unregistered.")
                                } catch {
                                    print("Failed to unregister login item: \(error.localizedDescription)")
                                    // Optionally, revert toggle state if unregistration fails
                                    viewModel.launchAtLogin = true
                                }
                            } else {
                                print("Login item already disabled.")
                            }
                        }
                    }

                Picker(localization.l("settings.default.mode"), selection: $viewModel.defaultOptimizeMode) {
                    ForEach(OptimizeMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .onChange(of: viewModel.defaultOptimizeMode) { _, _ in
                    viewModel.saveSettings()
                }

                Toggle(localization.l("settings.show.toast"), isOn: $viewModel.showCopyToast)
                    .onChange(of: viewModel.showCopyToast) { _, _ in
                        viewModel.saveSettings()
                    }
            }

            // MARK: - System Prompts
            Section(localization.l("settings.system.prompts")) {
                Text(localization.l("settings.system.prompts.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(OptimizeMode.allCases, id: \.self) { mode in
                    NavigationLink {
                        SystemPromptEditorView(mode: mode)
                    } label: {
                        HStack {
                            Text(mode.localizedName)
                            Spacer()
                            if OptimizeMode.getCustomPrompt(for: mode) != mode.defaultSystemPrompt {
                                Text("已自定义")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Button(localization.l("settings.system.prompts.reset.all"), role: .destructive) {
                    for mode in OptimizeMode.allCases {
                        OptimizeMode.resetToDefault(for: mode)
                    }
                    ToastManager.shared.success("已恢复默认")
                }
            }

            // MARK: - Data Management
            Section(localization.l("settings.data.management")) {
                HStack {
                    Button(localization.l("settings.export.data")) {
                        // Implement export logic
                        print("Export Data pressed")
                        // Example: Call storageService.exportData() and save to file
                    }
                    Button(localization.l("settings.import.data")) {
                        // Implement import logic
                        print("Import Data pressed")
                        // Example: Open file panel, load data, call storageService.importData()
                    }
                    Spacer()
                    Button(localization.l("settings.clear.data"), role: .destructive) {
                        // Implement clear all data logic with confirmation
                        print("Clear All Data pressed")
                    }
                }
            }

            // MARK: - About
            Section(localization.l("settings.about")) {
                HStack {
                    Text(localization.l("settings.version"))
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Button(localization.l("settings.check.update")) {
                    // Implement update check logic (Sparkle integration)
                    print("Check for Updates pressed")
                }
                .disabled(true) // Disable until Sparkle is integrated
            }

            // MARK: - Reset Settings
            Section {
                Button(localization.l("settings.reset"), role: .destructive) {
                    viewModel.resetSettings()
                    appState.updateSettings() // Update AppState after reset
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 500, maxWidth: 800, minHeight: 600)
        .onAppear {
            // Initial load of hotkey status for SMAppService
            viewModel.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        // 移除重复的 onChange 监听器，避免重复触发验证
        // API Key 和 customAPIEndpoint 的验证已在对应的 onChange 中处理
    }
}

// A helper View for recording hotkeys
struct HotkeyRecorder: View {
    let label: String
    @Binding var shortcut: KeyCombo // Our KeyCombo struct
    let hotkeyName: KeyboardShortcuts.Name
    @Environment(AppState.self) var appState // Needed to call setShortcut on hotkeyService

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            // KeyboardShortcuts.Recorder binds directly to the KeyboardShortcuts.Name.
            // We need to ensure our KeyCombo property on the ViewModel gets updated.
            KeyboardShortcuts.Recorder(for: hotkeyName) { _ in
                if let newShortcut = KeyboardShortcuts.getShortcut(for: hotkeyName) {
                    let newKeyCombo = KeyCombo(from: newShortcut)
                    self.shortcut = newKeyCombo // Update our local binding
                    appState.hotkeyService.setShortcut(newKeyCombo, for: hotkeyName) // Update the HotkeyService
                }
            }
        }
    }
}

// MARK: - System Prompt Editor View
/// 系统提示词编辑视图
struct SystemPromptEditorView: View {
    let mode: OptimizeMode
    @State private var promptText: String = ""
    @State private var localization = LocalizationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(mode.localizedName)
                        .font(.h3)
                    Text(localization.l("settings.system.prompts.description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Editor
            TextEditor(text: $promptText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.border, lineWidth: 1)
                )

            // Actions
            HStack {
                Button(localization.l("settings.system.prompts.reset")) {
                    promptText = mode.defaultSystemPrompt
                }
                .buttonStyle(.plain)
                .foregroundStyle(.orange)

                Spacer()

                Button(localization.l("common.cancel")) {
                    dismiss()
                }
                .buttonStyle(.plain)

                Button(localization.l("common.save")) {
                    OptimizeMode.saveCustomPrompt(promptText, for: mode)
                    ToastManager.shared.success(localization.l("toast.saved"))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.lg)
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.backgroundApp)
        .onAppear {
            promptText = OptimizeMode.getCustomPrompt(for: mode)
        }
    }
}

#Preview {
    // Provide mock services for the preview
    SettingsView(aiService: MockAIService(), hotkeyService: HotkeyService())
        .environment(AppState())
        .environment(\.modelContext, PromptCraftApp.sharedModelContainer.mainContext) // Provide a model context for preview
}