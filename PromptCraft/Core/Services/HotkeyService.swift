import Foundation
import KeyboardShortcuts
import Observation
import AppKit

/// 全局快捷键管理服务
/// 使用 KeyboardShortcuts 库实现全局快捷键功能
@Observable
class HotkeyService {
    // 暴露 KeyCombos 用于 UI 绑定
    var togglePanelKeyCombo: KeyCombo {
        didSet { saveHotkeys() }
    }
    var quickOptimizeKeyCombo: KeyCombo {
        didSet { saveHotkeys() }
    }
    var openLibraryKeyCombo: KeyCombo {
        didSet { saveHotkeys() }
    }

    init() {
        // 先设置默认值
        self.togglePanelKeyCombo = Self.defaultTogglePanelKeyCombo
        self.quickOptimizeKeyCombo = Self.defaultQuickOptimizeKeyCombo
        self.openLibraryKeyCombo = Self.defaultOpenLibraryKeyCombo
        // 然后加载保存的设置
        loadHotkeys()
        // 注册快捷键到系统
        registerShortcuts()
    }

    // MARK: - 快捷键管理

    /// 从 UserDefaults 加载快捷键设置
    private func loadHotkeys() {
        let defaults = UserDefaults.standard
        if let hotkeyData = defaults.data(forKey: HotkeySettings.storageKey),
           let hotkeySettings = try? JSONDecoder().decode(HotkeySettings.self, from: hotkeyData) {
            self.togglePanelKeyCombo = hotkeySettings.togglePanel
            self.quickOptimizeKeyCombo = hotkeySettings.quickOptimize
            self.openLibraryKeyCombo = hotkeySettings.openLibrary
        }
    }

    /// 保存当前快捷键设置到 UserDefaults
    func saveHotkeys() {
        let hotkeySettings = HotkeySettings(
            togglePanel: togglePanelKeyCombo,
            quickOptimize: quickOptimizeKeyCombo,
            openLibrary: openLibraryKeyCombo
        )
        if let encoded = try? JSONEncoder().encode(hotkeySettings) {
            UserDefaults.standard.set(encoded, forKey: HotkeySettings.storageKey)
        }
    }

    /// 注册快捷键到系统
    private func registerShortcuts() {
        print("[HotkeyService] Registering shortcuts to system")
        if let shortcut = togglePanelKeyCombo.toKeyboardShortcut() {
            KeyboardShortcuts.setShortcut(shortcut, for: .togglePanel)
            print("[HotkeyService] Registered togglePanel: \(shortcut)")
        } else {
            print("[HotkeyService] Warning: Failed to convert togglePanelKeyCombo to shortcut")
        }
        if let shortcut = quickOptimizeKeyCombo.toKeyboardShortcut() {
            KeyboardShortcuts.setShortcut(shortcut, for: .quickOptimize)
            print("[HotkeyService] Registered quickOptimize: \(shortcut)")
        } else {
            print("[HotkeyService] Warning: Failed to convert quickOptimizeKeyCombo to shortcut")
        }
        if let shortcut = openLibraryKeyCombo.toKeyboardShortcut() {
            KeyboardShortcuts.setShortcut(shortcut, for: .openLibrary)
            print("[HotkeyService] Registered openLibrary: \(shortcut)")
        } else {
            print("[HotkeyService] Warning: Failed to convert openLibraryKeyCombo to shortcut")
        }
        print("[HotkeyService] Shortcuts registration complete")
    }

    /// 设置特定快捷键并更新系统注册
    func setShortcut(_ keyCombo: KeyCombo, for name: KeyboardShortcuts.Name) {
        switch name {
        case .togglePanel:
            self.togglePanelKeyCombo = keyCombo
        case .quickOptimize:
            self.quickOptimizeKeyCombo = keyCombo
        case .openLibrary:
            self.openLibraryKeyCombo = keyCombo
        default:
            break
        }
        if let shortcut = keyCombo.toKeyboardShortcut() {
            KeyboardShortcuts.setShortcut(shortcut, for: name)
        }
        saveHotkeys()
    }

    // MARK: - 默认快捷键

    static var defaultTogglePanelKeyCombo: KeyCombo { .init(key: .p, modifiers: [.command, .shift]) }
    static var defaultQuickOptimizeKeyCombo: KeyCombo { .init(key: .o, modifiers: [.command, .shift]) }
    static var defaultOpenLibraryKeyCombo: KeyCombo { .init(key: .l, modifiers: [.command, .shift]) }

    // MARK: - 处理器注册

    /// 注册全局快捷键的处理器
    /// 应在应用启动时调用一次
    func registerHandlers(
        onTogglePanel: @escaping () -> Void,
        onQuickOptimize: @escaping () -> Void,
        onOpenLibrary: @escaping () -> Void
    ) {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { onTogglePanel() }
        KeyboardShortcuts.onKeyUp(for: .quickOptimize) { onQuickOptimize() }
        KeyboardShortcuts.onKeyUp(for: .openLibrary) { onOpenLibrary() }
    }
}

// MARK: - KeyboardShortcuts.Name 扩展

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel")
    static let quickOptimize = Self("quickOptimize")
    static let openLibrary = Self("openLibrary")
}

// MARK: - KeyCombo 转换扩展

extension KeyCombo {
    /// 从 KeyboardShortcuts.Shortcut 初始化 KeyCombo
    init(from shortcut: KeyboardShortcuts.Shortcut) {
        self.key = Key.from(shortcut.key)
        self.modifiers = Modifier.from(shortcut.modifiers)
    }

    /// 将 KeyCombo 转换为 KeyboardShortcuts.Shortcut
    func toKeyboardShortcut() -> KeyboardShortcuts.Shortcut? {
        guard let keyEquivalent = key.toKeyboardShortcutsKey() else {
            return nil
        }
        let cocoaModifiers = NSEvent.ModifierFlags(keyComboModifiers: modifiers)
        return KeyboardShortcuts.Shortcut(keyEquivalent, modifiers: cocoaModifiers)
    }
}

extension KeyCombo.Key {
    /// 转换为 KeyboardShortcuts.Key
    func toKeyboardShortcutsKey() -> KeyboardShortcuts.Key? {
        switch self {
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .f: return .f
        case .g: return .g
        case .h: return .h
        case .i: return .i
        case .j: return .j
        case .k: return .k
        case .l: return .l
        case .m: return .m
        case .n: return .n
        case .o: return .o
        case .p: return .p
        case .q: return .q
        case .r: return .r
        case .s: return .s
        case .t: return .t
        case .u: return .u
        case .v: return .v
        case .w: return .w
        case .x: return .x
        case .y: return .y
        case .z: return .z
        case .num0: return .zero
        case .num1: return .one
        case .num2: return .two
        case .num3: return .three
        case .num4: return .four
        case .num5: return .five
        case .num6: return .six
        case .num7: return .seven
        case .num8: return .eight
        case .num9: return .nine
        case .return: return .return
        case .tab: return .tab
        case .space: return .space
        case .delete: return .delete
        case .escape: return .escape
        case .upArrow: return .upArrow
        case .downArrow: return .downArrow
        case .leftArrow: return .leftArrow
        case .rightArrow: return .rightArrow
        case .f1: return .f1
        case .f2: return .f2
        case .f3: return .f3
        case .f4: return .f4
        case .f5: return .f5
        case .f6: return .f6
        case .f7: return .f7
        case .f8: return .f8
        case .f9: return .f9
        case .f10: return .f10
        case .f11: return .f11
        case .f12: return .f12
        case .unknown: return nil
        }
    }
}

extension NSEvent.ModifierFlags {
    /// 从 KeyCombo.Modifier 集合初始化
    init(keyComboModifiers modifiers: Set<KeyCombo.Modifier>) {
        self.init()
        if modifiers.contains(.command) { self.formUnion(.command) }
        if modifiers.contains(.shift) { self.formUnion(.shift) }
        if modifiers.contains(.option) { self.formUnion(.option) }
        if modifiers.contains(.control) { self.formUnion(.control) }
    }
}

// MARK: - KeyCombo.Key 从 KeyboardShortcuts.Key 转换

extension KeyCombo.Key {
    /// 从 KeyboardShortcuts.Key 创建 KeyCombo.Key
    static func from(_ key: KeyboardShortcuts.Key?) -> KeyCombo.Key {
        guard let key = key else { return .unknown }
        switch key {
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .f: return .f
        case .g: return .g
        case .h: return .h
        case .i: return .i
        case .j: return .j
        case .k: return .k
        case .l: return .l
        case .m: return .m
        case .n: return .n
        case .o: return .o
        case .p: return .p
        case .q: return .q
        case .r: return .r
        case .s: return .s
        case .t: return .t
        case .u: return .u
        case .v: return .v
        case .w: return .w
        case .x: return .x
        case .y: return .y
        case .z: return .z
        case .zero: return .num0
        case .one: return .num1
        case .two: return .num2
        case .three: return .num3
        case .four: return .num4
        case .five: return .num5
        case .six: return .num6
        case .seven: return .num7
        case .eight: return .num8
        case .nine: return .num9
        case .return: return .return
        case .tab: return .tab
        case .space: return .space
        case .delete: return .delete
        case .escape: return .escape
        case .upArrow: return .upArrow
        case .downArrow: return .downArrow
        case .leftArrow: return .leftArrow
        case .rightArrow: return .rightArrow
        case .f1: return .f1
        case .f2: return .f2
        case .f3: return .f3
        case .f4: return .f4
        case .f5: return .f5
        case .f6: return .f6
        case .f7: return .f7
        case .f8: return .f8
        case .f9: return .f9
        case .f10: return .f10
        case .f11: return .f11
        case .f12: return .f12
        default: return .unknown
        }
    }
}

// MARK: - KeyCombo.Modifier 从 NSEvent.ModifierFlags 转换

extension KeyCombo.Modifier {
    /// 从 NSEvent.ModifierFlags 创建 KeyCombo.Modifier 集合
    static func from(_ flags: NSEvent.ModifierFlags) -> Set<KeyCombo.Modifier> {
        var modifiers: Set<KeyCombo.Modifier> = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        return modifiers
    }
}
