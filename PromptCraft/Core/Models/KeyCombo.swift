import Foundation
import KeyboardShortcuts
import AppKit

// MARK: - KeyCombo Struct

/// A Codable and Hashable representation of a keyboard shortcut, including key and modifiers.
/// 用于存储和序列化快捷键组合
struct KeyCombo: Codable, Hashable {
    var key: Key
    var modifiers: Set<Modifier>

    // MARK: - Key Enum

    /// 支持的按键枚举
    enum Key: String, Codable, CaseIterable, Hashable {
        case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
        case num0 = "0", num1 = "1", num2 = "2", num3 = "3", num4 = "4"
        case num5 = "5", num6 = "6", num7 = "7", num8 = "8", num9 = "9"
        case `return`, tab, space, delete, escape
        case upArrow, downArrow, leftArrow, rightArrow
        case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
        case unknown
    }

    // MARK: - Modifier Enum

    /// 修饰键枚举
    enum Modifier: String, Codable, CaseIterable, Hashable {
        case command, shift, option, control
    }
}

// MARK: - HotkeySettings

/// 快捷键设置结构，用于 UserDefaults 存储
struct HotkeySettings: Codable {
    var togglePanel: KeyCombo
    var quickOptimize: KeyCombo
    var openLibrary: KeyCombo

    static let storageKey = "hotkey_settings"
}
