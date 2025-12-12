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

// 临时的 ContentView，用于验证运行
// 临时的 ContentView，用于验证运行
struct ContentView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab: Tab? = .optimize
    // 监听 LocalizationService 以响应语言变化
    @State private var localization = LocalizationService.shared

    enum Tab: String, CaseIterable, Identifiable {
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
            case .optimize: return "wand.and.stars"
            case .library: return "books.vertical"
            case .tags: return "tag"
            case .settings: return "gearshape"
            case .history: return "clock"
            case .favorites: return "star"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section {
                    NavigationLink(value: Tab.optimize) {
                        Label(Tab.optimize.localizedName, systemImage: Tab.optimize.icon)
                    }
                    NavigationLink(value: Tab.library) {
                        Label(Tab.library.localizedName, systemImage: Tab.library.icon)
                    }
                    NavigationLink(value: Tab.tags) {
                        Label(Tab.tags.localizedName, systemImage: Tab.tags.icon)
                    }
                    NavigationLink(value: Tab.settings) {
                        Label(Tab.settings.localizedName, systemImage: Tab.settings.icon)
                    }
                }

                Section {
                    NavigationLink(value: Tab.history) {
                        Label(Tab.history.localizedName, systemImage: Tab.history.icon)
                    }
                    NavigationLink(value: Tab.favorites) {
                        Label(Tab.favorites.localizedName, systemImage: Tab.favorites.icon)
                    }
                }
            }
            .navigationTitle("PromptCraft")
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
            switch selectedTab {
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
                OptimizeView()
            }
        }
    }
}
