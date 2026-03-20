import SwiftUI
import StoreKit

struct ProUpgradeSheet: View {
    @Environment(PurchaseManager.self) private var pm
    @Environment(\.dismiss) private var dismiss

    private let features = [
        "All premium themes",
        "Hi-res export (3× & 4×)",
        "All window frame styles",
        "No watermark on exports"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("SnapCode Pro")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                }
            }

            Button("Buy for \(pm.product?.displayPrice ?? "…")") {
                Task { await pm.purchase() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(pm.isLoading || pm.product == nil)

            Button("Restore Purchase") {
                Task { await pm.restorePurchases() }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            if let err = pm.errorMessage {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(32)
        .frame(width: 360)
        .onChange(of: pm.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}

#Preview {
    ProUpgradeSheet()
        .environment(PurchaseManager())
}
