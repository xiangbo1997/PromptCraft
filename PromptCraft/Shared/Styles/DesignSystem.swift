import SwiftUI
import AppKit

// ... (rest of the file)


enum DesignSystem {
    // MARK: - Colors
    static let primaryApp = Color.primaryApp
    static let primaryHover = Color.primaryHover
    static let primaryPressed = Color.primaryPressed
    
    static let secondaryApp = Color.secondaryApp
    static let success = Color.success
    static let warning = Color.warning
    static let error = Color.error
    
    static let backgroundApp = Color.backgroundApp
    static let surface = Color.surface
    static let border = Color.border
    static let divider = Color.divider
    
    static let textPrimary = Color.textPrimary
    static let textSecondary = Color.textSecondary
    static let textTertiary = Color.textTertiary
    static let textDisabled = Color.textDisabled
    
    static let infoBackground = Color.infoBackground
    static let successBackground = Color.successBackground
    static let warningBackground = Color.warningBackground
    static let errorBackground = Color.errorBackground
    static let infoText = Color.primaryApp
    
    // MARK: - Shadows
    static let shadowSm = Color.black.opacity(0.05)
    static let shadowMd = Color.black.opacity(0.1)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
}

// MARK: - Color Extensions
extension Color {
    // 主色
    static let primaryApp = Color(nsColor: NSColor(hex: "2563EB"))
    static let primaryHover = Color(nsColor: NSColor(hex: "1D4ED8"))
    static let primaryPressed = Color(nsColor: NSColor(hex: "1E40AF"))
    
    // 辅助色
    static let secondaryApp = Color(nsColor: NSColor(hex: "64748B"))
    static let success = Color(nsColor: NSColor(hex: "10B981"))
    static let warning = Color(nsColor: NSColor(hex: "F59E0B"))
    static let error = Color(nsColor: NSColor(hex: "EF4444"))
    
    // 中性色
    static let backgroundApp = Color(light: "F3F4F6", dark: "111827")
    static let surface = Color(light: "FFFFFF", dark: "1F2937")
    static let border = Color(light: "E5E7EB", dark: "374151")
    static let divider = Color(light: "E5E7EB", dark: "374151")
    
    // 文字色
    static let textPrimary = Color(light: "111827", dark: "F9FAFB")
    static let textSecondary = Color(light: "6B7280", dark: "D1D5DB")
    static let textTertiary = Color(light: "9CA3AF", dark: "9CA3AF")
    static let textDisabled = Color(light: "D1D5DB", dark: "4B5563")
    
    // 语义化背景
    static let infoBackground = Color(light: "EFF6FF", dark: "1E3A8A")
    static let successBackground = Color(light: "ECFDF5", dark: "064E3B")
    static let warningBackground = Color(light: "FFFBEB", dark: "78350F")
    static let errorBackground = Color(light: "FEF2F2", dark: "7F1D1D")
    
    // Shadows (as static vars for convenience if needed, though usually used via modifiers)
    static let shadowSm = Color.black.opacity(0.05)
    static let shadowMd = Color.black.opacity(0.1)
    
    init(light: String, dark: String) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name.rawValue.lowercased().contains("dark") {
                return NSColor(hex: dark)
            } else {
                return NSColor(hex: light)
            }
        }))
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        let alpha = CGFloat(a) / 255.0

        self.init(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

// MARK: - Typography

extension Font {
    static let h1 = Font.system(size: 28, weight: .bold)
    static let h2 = Font.system(size: 22, weight: .bold)
    static let h3 = Font.system(size: 18, weight: .semibold)
    static let h4 = Font.system(size: 16, weight: .semibold)
    
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyRegular = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)
    
    static let caption = Font.system(size: 11, weight: .regular)
}

// MARK: - Components

struct AppButtonStyle: ButtonStyle {
    var size: ControlSize = .regular
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let backgroundColor: Color
        if isPrimary {
            backgroundColor = isPressed ? Color.primaryPressed : Color.primaryApp
        } else {
            backgroundColor = Color.clear
        }
        
        let foregroundColor: Color = isPrimary ? .white : .primaryApp
        let borderColor: Color = isPrimary ? .clear : .border
        
        let font: Font = size == .large ? .bodyLarge : .bodyRegular
        let horizontalPadding: CGFloat = size == .large ? 20 : 16
        let verticalPadding: CGFloat = size == .large ? 10 : 8
        let cornerRadius: CGFloat = CornerRadius.sm
        
        let label = configuration.label
            .font(font)
            .fontWeight(.medium)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            
        let backgroundShape = RoundedRectangle(cornerRadius: cornerRadius)
        
        return label
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(backgroundShape)
            .overlay(
                backgroundShape
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static var appPrimary: AppButtonStyle { AppButtonStyle(isPrimary: true) }
    static var appSecondary: AppButtonStyle { AppButtonStyle(isPrimary: false) }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = Spacing.md
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.border, lineWidth: 1)
            )
            .shadow(color: Color.shadowSm, radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
