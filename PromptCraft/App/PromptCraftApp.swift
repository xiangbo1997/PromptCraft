import SwiftUI
import SwiftData

@main
struct PromptCraftApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // 使用 @AppStorage 直接跟踪主题，完全独立于 @Observable
    @AppStorage("app_theme") private var storedTheme: String = Theme.system.rawValue

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Prompt.self,
            Category.self,
            Tag.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var currentColorScheme: ColorScheme? {
        Theme(rawValue: storedTheme)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .toastContainer()
                .preferredColorScheme(currentColorScheme)
                .task {
                    // 延迟设置 AppDelegate 的依赖
                    appDelegate.appState = appState
                    appDelegate.hotkeyService = appState.hotkeyService
                    appDelegate.setupAfterStateInjection()
                }
        }
        .modelContainer(Self.sharedModelContainer)
    }
}

// 主内容视图
struct ContentView: View {
    @Environment(AppState.self) var appState
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                // 主功能区
                Section {
                    NavigationLink(value: MainTab.scenes) {
                        Label(MainTab.scenes.localizedName, systemImage: MainTab.scenes.icon)
                    }
                    NavigationLink(value: MainTab.optimize) {
                        Label(MainTab.optimize.localizedName, systemImage: MainTab.optimize.icon)
                    }
                }

                // 数据管理
                Section {
                    NavigationLink(value: MainTab.library) {
                        Label(MainTab.library.localizedName, systemImage: MainTab.library.icon)
                    }
                    NavigationLink(value: MainTab.history) {
                        Label(MainTab.history.localizedName, systemImage: MainTab.history.icon)
                    }
                    NavigationLink(value: MainTab.favorites) {
                        Label(MainTab.favorites.localizedName, systemImage: MainTab.favorites.icon)
                    }
                    NavigationLink(value: MainTab.tags) {
                        Label(MainTab.tags.localizedName, systemImage: MainTab.tags.icon)
                    }
                }

                // 设置
                Section {
                    NavigationLink(value: MainTab.settings) {
                        Label(MainTab.settings.localizedName, systemImage: MainTab.settings.icon)
                    }
                }
            }
            .navigationTitle("SparkPrompt")
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    HStack {
                        Text(localization.l("settings.hotkeys"))
                        Spacer()
                        Text("⌘⇧P")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(nsColor: .controlBackgroundColor))
            }
        } detail: {
            switch appState.selectedTab {
            case .scenes:
                SceneLibraryView()
            case .optimize:
                OptimizeView()
            case .library:
                LibraryView(storageService: appState.storageService)
            case .history:
                HistoryView(storageService: appState.storageService)
            case .settings:
                SettingsView(aiService: appState.aiService, hotkeyService: appState.hotkeyService)
            case .tags:
                TagsCategoriesView(storageService: appState.storageService)
            case .favorites:
                FavoritesView(storageService: appState.storageService)
            case .none:
                SceneLibraryView()
            }
        }
    }
}
