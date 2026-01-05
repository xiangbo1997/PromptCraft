import SwiftUI
import StoreKit

// MARK: - 付费墙视图
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let reason: RestrictionReason
    let subscriptionService: SubscriptionService

    @State private var storeKitService = StoreKitService.shared
    @State private var isProcessing = false
    @State private var selectedProductIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    restrictionCard
                    benefitsSection
                    pricingSection
                }
                .padding(Spacing.xl)
            }
        }
        .frame(width: 500, height: 650)
        .background(Color.backgroundApp)
    }

    // MARK: - 头部
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("升级 Pro")
                    .font(.h2)
                    .foregroundStyle(Color.textPrimary)
                Text("解锁全部功能，提升创作效率")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color.surface)
    }

    // MARK: - 限制原因卡片
    private var restrictionCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: reason == .premiumRequired ? "crown.fill" : "clock.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundStyle(Color.warning)
                .frame(width: 48, height: 48)
                .background(Color.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(reason.title)
                    .font(.h4)
                    .foregroundStyle(Color.textPrimary)
                Text(reason.message)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.warning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 权益列表
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Pro 专业版权益")
                .font(.h4)
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(ProBenefit.all) { benefit in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: benefit.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.primaryApp)
                            .frame(width: 32, height: 32)
                            .background(Color.infoBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(benefit.title)
                                .font(.bodyRegular)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)
                            Text(benefit.description)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.success)
                    }
                    .padding(Spacing.sm)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }
        }
    }

    // MARK: - 价格区域
    private var pricingSection: some View {
        VStack(spacing: Spacing.md) {
            // StoreKit 产品或默认价格
            if storeKitService.products.isEmpty {
                defaultPricingCard
            } else {
                storeKitPricingCards
            }

            // 订阅按钮
            Button(action: { Task { await handleSubscribe() } }) {
                HStack {
                    if isProcessing || storeKitService.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(isProcessing ? "处理中..." : "立即订阅")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.primaryApp)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
            .disabled(isProcessing || storeKitService.isLoading)

            // 试用按钮
            if !subscriptionService.status.isTrialUsed {
                Button(action: { handleTrial() }) {
                    Text("免费试用 7 天")
                        .font(.bodyRegular)
                        .foregroundStyle(Color.primaryApp)
                }
                .buttonStyle(.plain)
            }

            // 恢复购买
            Button(action: { Task { await handleRestore() } }) {
                Text("恢复购买")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)

            // 错误信息
            if let error = storeKitService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.error)
            }

            // 说明
            Text("订阅将自动续费，可随时在系统设置中取消")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 默认价格卡片（StoreKit 未加载时）
    private var defaultPricingCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("¥")
                    .font(.h3)
                    .foregroundStyle(Color.textPrimary)
                Text("28")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("/月")
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textSecondary)
            }

            Text("首月特惠，原价 ¥38/月")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
                .strikethrough()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.primaryApp.opacity(0.1), Color.secondaryApp.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.primaryApp.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - StoreKit 价格卡片
    private var storeKitPricingCards: some View {
        HStack(spacing: Spacing.md) {
            ForEach(Array(storeKitService.products.enumerated()), id: \.element.id) { index, product in
                ProductCard(
                    product: product,
                    isSelected: selectedProductIndex == index,
                    isPopular: index == 1 // 年度订阅标记为热门
                ) {
                    selectedProductIndex = index
                }
            }
        }
    }

    // MARK: - 操作
    private func handleSubscribe() async {
        if storeKitService.products.isEmpty {
            // StoreKit 未加载，使用模拟购买
            isProcessing = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let oneMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            subscriptionService.activatePro(expirationDate: oneMonth)
            isProcessing = false
            ToastManager.shared.success("订阅成功！欢迎使用 Pro 版")
            dismiss()
        } else {
            // 使用 StoreKit 购买
            let product = storeKitService.products[selectedProductIndex]
            isProcessing = true
            do {
                let success = try await storeKitService.purchase(product)
                isProcessing = false
                if success {
                    ToastManager.shared.success("订阅成功！欢迎使用 Pro 版")
                    dismiss()
                }
            } catch {
                isProcessing = false
                ToastManager.shared.error("购买失败: \(error.localizedDescription)")
            }
        }
    }

    private func handleTrial() {
        if subscriptionService.activateTrial() {
            ToastManager.shared.success("试用已激活！7 天内免费使用 Pro 功能")
            dismiss()
        }
    }

    private func handleRestore() async {
        isProcessing = true
        let success = await storeKitService.restorePurchases()
        isProcessing = false
        if success {
            ToastManager.shared.success("购买已恢复")
            dismiss()
        } else {
            ToastManager.shared.error("未找到可恢复的购买记录")
        }
    }
}

// MARK: - 产品卡片
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                if isPopular {
                    Text("最划算")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.warning)
                        .clipShape(Capsule())
                }

                Text(product.displayName)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                Text(product.displayPrice)
                    .font(.h3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                Text(product.periodDescription)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.primaryApp.opacity(0.1) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isSelected ? Color.primaryApp : Color.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 使用量指示器
struct UsageIndicatorView: View {
    let subscriptionService: SubscriptionService

    var body: some View {
        if subscriptionService.isPro {
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                Text("Pro")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.warning)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.warningBackground)
            .clipShape(Capsule())
        } else {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                Text("\(subscriptionService.remainingGenerations)/3")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(subscriptionService.remainingGenerations > 0 ? Color.textSecondary : Color.error)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    PaywallView(
        reason: .dailyLimitReached,
        subscriptionService: SubscriptionService.shared
    )
}
