import SwiftUI

struct ProLockedRow<Content: View>: View {
    let label: String
    let isPro: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isPro {
            content()
        } else {
            content()
                .disabled(true)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.ultraThinMaterial)
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
        }
    }
}
