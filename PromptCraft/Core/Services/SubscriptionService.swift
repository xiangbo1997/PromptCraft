import Foundation
import Observation

// MARK: - 订阅计划
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "免费版"
        case .pro: return "Pro 专业版"
        }
    }

    var description: String {
        switch self {
        case .free: return "基础功能，每日限量使用"
        case .pro: return "无限使用，解锁全部高级模板"
        }
    }

    /// 每日免费生成次数
    var dailyGenerationLimit: Int {
        switch self {
        case .free: return 3
        case .pro: return Int.max
        }
    }

    /// 是否可以使用 Premium 模板
    var canUsePremiumTemplates: Bool {
        switch self {
        case .free: return false
        case .pro: return true
        }
    }
}

// MARK: - 订阅状态
struct SubscriptionStatus: Codable {
    var plan: SubscriptionPlan
    var expirationDate: Date?
    var isTrialUsed: Bool

    var isActive: Bool {
        guard plan == .pro else { return false }
        guard let expiration = expirationDate else { return false }
        return expiration > Date()
    }

    var effectivePlan: SubscriptionPlan {
        return isActive ? .pro : .free
    }

    static var free: SubscriptionStatus {
        SubscriptionStatus(plan: .free, expirationDate: nil, isTrialUsed: false)
    }
}

// MARK: - 使用统计
struct UsageStats: Codable {
    var date: String
    var generationCount: Int

    static func today() -> UsageStats {
        UsageStats(date: Self.todayString(), generationCount: 0)
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - 订阅服务
@MainActor
@Observable
final class SubscriptionService {

    static let shared = SubscriptionService()

    private(set) var status: SubscriptionStatus = .free
    private(set) var todayUsage: UsageStats = .today()

    var currentPlan: SubscriptionPlan { status.effectivePlan }

    var remainingGenerations: Int {
        let limit = currentPlan.dailyGenerationLimit
        if limit == Int.max { return Int.max }
        return max(0, limit - todayUsage.generationCount)
    }

    var canGenerate: Bool { true }  // 移除限制，始终可以生成
    var isPro: Bool { true }  // 移除 Pro 限制，所有功能免费开放

    private let statusKey = "subscription_status"
    private let usageKey = "daily_usage_stats"

    private init() {
        loadData()
        checkAndResetDailyUsage()
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: statusKey),
           let decoded = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) {
            status = decoded
        }
        if let data = UserDefaults.standard.data(forKey: usageKey),
           let decoded = try? JSONDecoder().decode(UsageStats.self, from: data) {
            todayUsage = decoded
        }
    }

    private func saveStatus() {
        if let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: statusKey)
        }
    }

    private func saveUsage() {
        if let data = try? JSONEncoder().encode(todayUsage) {
            UserDefaults.standard.set(data, forKey: usageKey)
        }
    }

    private func checkAndResetDailyUsage() {
        let today = UsageStats.todayString()
        if todayUsage.date != today {
            todayUsage = UsageStats(date: today, generationCount: 0)
            saveUsage()
        }
    }

    func recordGeneration() {
        checkAndResetDailyUsage()
        todayUsage.generationCount += 1
        saveUsage()
    }

    func canUseTemplate(_ template: SceneTemplate) -> Bool {
        // 移除限制，所有模板都可以使用
        return true
    }

    func getRestrictionReason(for template: SceneTemplate) -> RestrictionReason? {
        // 移除限制，永远不返回限制原因
        return nil
    }

    func activatePro(expirationDate: Date) {
        status = SubscriptionStatus(plan: .pro, expirationDate: expirationDate, isTrialUsed: status.isTrialUsed)
        saveStatus()
    }

    func activateTrial() -> Bool {
        guard !status.isTrialUsed else { return false }
        let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        status = SubscriptionStatus(plan: .pro, expirationDate: trialEnd, isTrialUsed: true)
        saveStatus()
        return true
    }

    func deactivate() {
        status = SubscriptionStatus(plan: .free, expirationDate: nil, isTrialUsed: status.isTrialUsed)
        saveStatus()
    }

    func restorePurchases() async -> Bool {
        // 调用 StoreKitService 恢复购买
        return await StoreKitService.shared.restorePurchases()
    }
}

// MARK: - 限制原因
enum RestrictionReason {
    case premiumRequired
    case dailyLimitReached

    var title: String {
        switch self {
        case .premiumRequired: return "Pro 专属模板"
        case .dailyLimitReached: return "今日次数已用完"
        }
    }

    var message: String {
        switch self {
        case .premiumRequired: return "此模板为 Pro 专业版专属，升级后即可使用全部高级模板"
        case .dailyLimitReached: return "免费版每日可生成 3 次，升级 Pro 版享受无限使用"
        }
    }
}

// MARK: - Pro 权益
struct ProBenefit: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String

    static let all: [ProBenefit] = [
        ProBenefit(icon: "infinity", title: "无限生成", description: "不限次数，随时随地使用"),
        ProBenefit(icon: "crown.fill", title: "全部高级模板", description: "解锁所有 Pro 专属场景模板"),
        ProBenefit(icon: "bolt.fill", title: "优先响应", description: "更快的 AI 响应速度"),
        ProBenefit(icon: "sparkles", title: "持续更新", description: "第一时间获取新模板和功能")
    ]
}
