import SwiftUI

// Toast 消息类型
enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .primaryApp
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return .successBackground
        case .error: return .errorBackground
        case .warning: return .warningBackground
        case .info: return .infoBackground
        }
    }
}

// Toast 消息模型
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: TimeInterval

    init(type: ToastType, message: String, duration: TimeInterval = 2.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// Toast 视图
struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.type.icon)
                .foregroundStyle(toast.type.color)
                .font(.system(size: 16, weight: .medium))

            Text(toast.message)
                .font(.bodyRegular)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(toast.type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.shadowMd, radius: 8, x: 0, y: 4)
    }
}

// Toast 管理器 - 全局单例
@Observable
class ToastManager {
    static let shared = ToastManager()

    var currentToast: ToastMessage?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        // 取消之前的定时器
        dismissTask?.cancel()

        // 显示新 Toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = ToastMessage(type: type, message: message, duration: duration)
        }

        // 设置自动消失
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                currentToast = nil
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }

    // 便捷方法
    func success(_ message: String) {
        show(message, type: .success)
    }

    func error(_ message: String) {
        show(message, type: .error, duration: 3.0)
    }

    func warning(_ message: String) {
        show(message, type: .warning)
    }

    func info(_ message: String) {
        show(message, type: .info)
    }
}

// Toast 容器修饰符
struct ToastContainerModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .padding(.top, 60)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .zIndex(1000)
                }
            }
    }
}

extension View {
    /// 添加 Toast 容器到视图
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastView(toast: ToastMessage(type: .success, message: "已复制到剪贴板"))
        ToastView(toast: ToastMessage(type: .error, message: "操作失败，请重试"))
        ToastView(toast: ToastMessage(type: .warning, message: "API 调用次数即将达到限额"))
        ToastView(toast: ToastMessage(type: .info, message: "提示词已保存"))
    }
    .padding()
    .frame(width: 400, height: 300)
    .background(Color.backgroundApp)
}
