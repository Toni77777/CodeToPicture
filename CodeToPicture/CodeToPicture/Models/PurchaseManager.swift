import Foundation
import StoreKit

@Observable
@MainActor
final class PurchaseManager {
    var isPro: Bool = true // TODO: revert to UserDefaults.standard.bool(forKey: "isPro") before release
    var product: Product?
    var isLoading: Bool = false
    var errorMessage: String?

    private let productID = "com.snapcode.pro"
    @ObservationIgnored
    private var updatesTask: Task<Void, Never>?

    init() {
        let id = productID
        updatesTask = Task {
            await listenForTransactionUpdates(productID: id)
        }
        Task { await checkEntitlements() }
        Task { await loadProduct() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        isLoading = true
        if let products = try? await Product.products(for: [productID]) {
            product = products.first
        }
        isLoading = false
    }

    func purchase() async {
        guard let product else { return }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                isPro = true
                UserDefaults.standard.set(true, forKey: "isPro")
                await tx.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        try? await AppStore.sync()
        await checkEntitlements()
        isLoading = false
    }

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == productID {
                isPro = true
                UserDefaults.standard.set(true, forKey: "isPro")
                return
            }
        }
    }

    // MARK: - Private

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let tx):
            return tx
        case .unverified(_, let error):
            throw error
        }
    }

    private func listenForTransactionUpdates(productID: String) async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result, tx.productID == productID {
                isPro = true
                UserDefaults.standard.set(true, forKey: "isPro")
                await tx.finish()
            }
        }
    }
}
