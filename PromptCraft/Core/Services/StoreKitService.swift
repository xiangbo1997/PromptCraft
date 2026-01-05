import Foundation
import StoreKit

// MARK: - 产品 ID
enum ProductID: String, CaseIterable {
    case proMonthly = "com.promptcraft.pro.monthly"
    case proYearly = "com.promptcraft.pro.yearly"

    var displayName: String {
        switch self {
        case .proMonthly: return "Pro 月度订阅"
        case .proYearly: return "Pro 年度订阅"
        }
    }
}

// MARK: - StoreKit 服务
@MainActor
@Observable
final class StoreKitService {

    static let shared = StoreKitService()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private nonisolated(unsafe) var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    nonisolated deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - 加载产品

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            print("[StoreKit] Loaded \(products.count) products")
        } catch {
            errorMessage = "无法加载产品信息: \(error.localizedDescription)"
            print("[StoreKit] Error loading products: \(error)")
        }

        isLoading = false
    }

    // MARK: - 购买产品

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()

                // 激活订阅
                activateSubscription(for: product)

                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                errorMessage = "购买待处理，请稍后查看"
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "购买失败: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if !purchasedProductIDs.isEmpty {
                // 恢复订阅状态
                for productID in purchasedProductIDs {
                    if let product = products.first(where: { $0.id == productID }) {
                        activateSubscription(for: product)
                    }
                }
                isLoading = false
                return true
            } else {
                isLoading = false
                errorMessage = "未找到可恢复的购买"
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 检查订阅状态

    func checkSubscriptionStatus() async {
        await updatePurchasedProducts()

        // 检查是否有有效订阅
        for productID in purchasedProductIDs {
            if let product = products.first(where: { $0.id == productID }) {
                activateSubscription(for: product)
                return
            }
        }

        // 没有有效订阅，降级为免费版
        SubscriptionService.shared.deactivate()
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("[StoreKit] Entitlement verification failed: \(error)")
            }
        }

        purchasedProductIDs = purchased
        print("[StoreKit] Purchased products: \(purchased)")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func activateSubscription(for product: Product) {
        // 根据产品类型设置过期时间
        let expirationDate: Date

        if product.id == ProductID.proMonthly.rawValue {
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        } else if product.id == ProductID.proYearly.rawValue {
            expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        } else {
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        }

        SubscriptionService.shared.activatePro(expirationDate: expirationDate)
        print("[StoreKit] Activated Pro subscription until \(expirationDate)")
    }
}

// MARK: - StoreKit 错误
enum StoreKitError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "购买验证失败"
        case .productNotFound:
            return "产品未找到"
        }
    }
}

// MARK: - 产品扩展
extension Product {
    var localizedPrice: String {
        displayPrice
    }

    var periodDescription: String {
        guard let subscription = subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "/月" : "/\(subscription.subscriptionPeriod.value)个月"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "/年" : "/\(subscription.subscriptionPeriod.value)年"
        case .week:
            return "/周"
        case .day:
            return "/天"
        @unknown default:
            return ""
        }
    }
}
