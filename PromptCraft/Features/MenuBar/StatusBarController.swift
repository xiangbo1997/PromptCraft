import AppKit
import SwiftUI
import KeyboardShortcuts

/// Manages the application's menu bar item and popover.
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let appState: AppState
    private let hotkeyService: HotkeyService

    init(appState: AppState, hotkeyService: HotkeyService) {
        self.appState = appState
        self.hotkeyService = hotkeyService
        super.init()
        
        setupStatusItem()
        setupPopover()
        registerHotkeys()
    }
    
    /// Configures the NSStatusItem (the menu bar icon).
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "SparkPrompt")
            button.action = #selector(togglePopover)
            button.target = self
            button.toolTip = "SparkPrompt"
        }
    }
    
    /// Configures the NSPopover to host our SwiftUI content.
    private func setupPopover() {
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 360, height: 500)
        self.popover.behavior = .semitransient // Dismisses when clicking outside
        self.popover.delegate = self // Set delegate to handle popover events

        // Host the SwiftUI view inside the popover
        let menuBarPopoverView = MenuBarPopover()
            .environment(appState) // Pass AppState to the SwiftUI view hierarchy
            .frame(width: 360, height: 500)

        self.popover.contentViewController = NSHostingController(rootView: menuBarPopoverView)
    }
    
    /// Registers global hotkey handlers with the HotkeyService.
    private func registerHotkeys() {
        print("[StatusBarController] Registering hotkey handlers")
        hotkeyService.registerHandlers(
            onTogglePanel: { [weak self] in
                print("[Hotkey] Toggle Panel triggered")
                self?.togglePopover()
            },
            onQuickOptimize: { [weak self] in
                print("[Hotkey] Quick Optimize triggered")
                self?.handleQuickOptimizeHotkey()
            },
            onOpenLibrary: { [weak self] in
                print("[Hotkey] Open Library triggered")
                self?.handleOpenLibraryHotkey()
            }
        )
        print("[StatusBarController] Hotkey handlers registered")
    }
    
    // MARK: - Popover Actions

    /// Toggles the visibility of the popover.
    @objc private func togglePopover() {
        if popover.isShown {
            hidePopover()
        } else {
            showPopover()
        }
    }
    
    /// Shows the popover, positioning it relative to the status item.
    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Make the popover window key to ensure it receives input focus
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    /// Hides the popover.
    private func hidePopover() {
        popover.performClose(nil)
    }
    
    // MARK: - Hotkey Handlers (for actions other than toggling the panel itself)

    private func handleQuickOptimizeHotkey() {
        print("Quick Optimize Hotkey Pressed!")
        // 打开主窗口并导航到优化标签页
        Task { @MainActor in
            appState.navigateToTab(.optimize)
        }
    }

    private func handleOpenLibraryHotkey() {
        print("Open Library Hotkey Pressed!")
        // 打开主窗口并导航到提示词库标签页
        Task { @MainActor in
            appState.navigateToTab(.library)
        }
    }
}

// MARK: - NSPopoverDelegate

extension StatusBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        // Perform any cleanup or state updates when the popover closes
        print("Popover did close.")
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        // Return true if the popover should be allowed to detach into its own window
        return false
    }
}
