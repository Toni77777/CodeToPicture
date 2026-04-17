import SwiftUI

struct PreviewView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(EditorViewModel.self) private var editorVM
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var vm = PreviewViewModel()
    @State private var exportVM = ExportViewModel()
    @State private var showBatchExport = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical]) {
                    canvasWithCard
                        .padding(40)
                }
                .onAppear {
                    vm.computeDimensions(
                        containerWidth: geo.size.width - 80,
                        code: editorVM.code,
                        settings: settings
                    )
                }
                .onChange(of: geo.size) { _, newSize in
                    vm.computeDimensions(
                        containerWidth: newSize.width - 80,
                        code: editorVM.code,
                        settings: settings
                    )
                }
            }

            statusBar
        }
        .onChange(of: editorVM.code) { _, newCode in
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: newCode,
                settings: settings
            )
        }
        .onChange(of: settings.padding) {
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: editorVM.code,
                settings: settings
            )
        }
        .onChange(of: settings.fontSize) {
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: editorVM.code,
                settings: settings
            )
        }
        .onChange(of: settings.showWindowFrame) {
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: editorVM.code,
                settings: settings
            )
        }
        .onChange(of: settings.canvasPadding) {
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: editorVM.code,
                settings: settings
            )
        }
        .onChange(of: settings.cornerRadius) {
            vm.computeDimensions(
                containerWidth: vm.displayWidth,
                code: editorVM.code,
                settings: settings
            )
        }
        .overlay(alignment: .bottom) {
            if !vm.statusMessage.isEmpty {
                Text(vm.statusMessage)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 60)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.statusMessage)
        .onChange(of: exportVM.statusMessage) { _, msg in
            if !msg.isEmpty { vm.showStatus(msg) }
        }
        .sheet(isPresented: $exportVM.showProSheet) {
            ProUpgradeSheet()
        }
        .sheet(isPresented: $showBatchExport) {
            BatchExportView()
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack {
            Text("\(exportImageWidth) \u{00D7} \(exportImageHeight) px @ \(Int(settings.exportScale))\u{00D7}")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

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

            Button("Export PNG") {
                Task {
                    await exportVM.exportPNG(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: purchaseManager.isPro
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(exportVM.isExporting)

            exportMenu
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    // MARK: - Export menu

    private var exportMenu: some View {
        Menu {
            Button("PNG") {
                Task {
                    await exportVM.exportPNG(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: purchaseManager.isPro
                    )
                }
            }

            Divider()

            Button("SVG \u{2B50}") {
                Task {
                    await exportVM.exportSVGFile(
                        code: editorVM.code,
                        language: editorVM.language,
                        theme: themeManager.selectedTheme,
                        settings: settings,
                        isPro: purchaseManager.isPro
                    )
                }
            }

            Button("PDF \u{2B50}") {
                Task {
                    let cardW = max(vm.displayWidth, 300)
                    let cardH = max(vm.displayHeight, 200)
                    await exportVM.exportPDFFile(
                        cardView: exportCard,
                        size: CGSize(
                            width: cardW + settings.canvasPadding * 2,
                            height: cardH + settings.canvasPadding * 2
                        ),
                        isPro: purchaseManager.isPro
                    )
                }
            }

            Divider()

            Button("Batch Export \u{2B50}") {
                showBatchExport = true
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(exportVM.isExporting)
    }

    // MARK: - Export dimensions (includes canvas padding)

    private var exportImageWidth: Int {
        Int((max(vm.displayWidth, 300) + settings.canvasPadding * 2) * settings.exportScale)
    }

    private var exportImageHeight: Int {
        Int((max(vm.displayHeight, 200) + settings.canvasPadding * 2) * settings.exportScale)
    }

    // MARK: - Canvas with card

    private var canvasWithCard: some View {
        let cardW = max(vm.displayWidth, 300)
        let cardH = max(vm.displayHeight, 200)
        let totalW = cardW + settings.canvasPadding * 2
        let totalH = cardH + settings.canvasPadding * 2

        return ZStack {
            CanvasBackgroundView(background: settings.canvasBackground)
                .frame(width: totalW, height: totalH)
                .clipShape(RoundedRectangle(cornerRadius: settings.canvasCornerRadius))

            CodeCardView()
                .frame(width: cardW, height: cardH)
        }
        .frame(width: totalW, height: totalH)
    }

    // MARK: - Export card

    private var exportCard: some View {
        let cardW = max(vm.displayWidth, 300)
        let cardH = max(vm.displayHeight, 200)
        let totalW = cardW + settings.canvasPadding * 2
        let totalH = cardH + settings.canvasPadding * 2

        return ZStack {
            CanvasBackgroundView(background: settings.canvasBackground)
                .frame(width: totalW, height: totalH)
                .clipShape(RoundedRectangle(cornerRadius: settings.canvasCornerRadius))

            CodeCardView()
                .frame(width: cardW, height: cardH)
        }
        .frame(width: totalW, height: totalH)
        .environment(settings)
        .environment(editorVM)
        .environment(themeManager)
    }
}

#Preview {
    PreviewView()
        .environment(AppSettings())
        .environment(EditorViewModel())
        .environment(ThemeManager())
        .environment(PurchaseManager())
        .frame(width: 700, height: 500)
}
