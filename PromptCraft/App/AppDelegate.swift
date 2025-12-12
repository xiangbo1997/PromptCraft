import AppKit
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    // AppState 由 SwiftUI 创建，通过 onAppear 注入
    var appState: AppState?
    var statusBarController: StatusBarController?

    // HotkeyService 由 AppState 提供
    var hotkeyService: HotkeyService?

    // 标记是否已经设置完成
    private var isSetupComplete = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // applicationDidFinishLaunching 可能在 SwiftUI 视图 onAppear 之前调用
        // 所以这里不再要求 appState 必须存在
        print("[AppDelegate] applicationDidFinishLaunching called")
    }

    /// 在 SwiftUI 视图注入 AppState 后调用此方法完成设置
    func setupAfterStateInjection() {
        // 防止重复设置
        guard !isSetupComplete else { return }

        guard let appState = appState, let hotkeyService = hotkeyService else {
            print("[AppDelegate] Warning: setupAfterStateInjection called but appState or hotkeyService is nil")
            return
        }

        print("[AppDelegate] Setting up StatusBarController and hotkeys")

        // 初始化 StatusBarController
        statusBarController = StatusBarController(appState: appState, hotkeyService: hotkeyService)

        // 初始化默认分类
        Task { @MainActor in
            appState.storageService.setupDefaultCategoriesIfNeeded()
        }

        isSetupComplete = true
        print("[AppDelegate] Setup complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate.")
    }
}
