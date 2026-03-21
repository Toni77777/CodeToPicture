import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(EditorViewModel.self) private var editorVM
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var exportVM = ExportViewModel()
    @State private var showProSheet = false

    var body: some View {
        VStack(spacing: 0) {
            CodeEditorView()
                .frame(height: 300)

            Divider()

            ThemePicker(onProRequired: { showProSheet = true })
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            Divider()

            bottomBar
        }
        .frame(width: 320, height: 480)
        .overlay(alignment: .bottom) {
            if !exportVM.statusMessage.isEmpty {
                Text(exportVM.statusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: exportVM.statusMessage)
        .sheet(isPresented: $showProSheet) {
            ProUpgradeSheet()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            Button("Export PNG") {
                Task {
                    await exportVM.exportPNG(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: purchaseManager.isPro
                    )
                }
            }
            .disabled(exportVM.isExporting)

            Button("Copy") {
                Task {
                    await exportVM.copyToClipboard(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: purchaseManager.isPro
                    )
                }
            }
            .disabled(exportVM.isExporting)

            Spacer()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first { $0.className.contains("AppKitWindow") || $0.isKeyWindow }?
                    .makeKeyAndOrderFront(nil)
            } label: {
                HStack(spacing: 2) {
                    Text("Open App")
                    Image(systemName: "arrow.up.forward")
                        .font(.caption2)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    // MARK: - Export card

    private var exportCard: some View {
        CodeCardView()
            .frame(width: 300, height: 240)
            .environment(settings)
            .environment(editorVM)
            .environment(themeManager)
    }
}

#Preview {
    MenuBarPopoverView()
        .environment(EditorViewModel())
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(PurchaseManager())
}
