import SwiftUI

struct PreviewView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(EditorViewModel.self) private var editorVM
    @Environment(ThemeManager.self) private var themeManager
    @State private var vm = PreviewViewModel()
    @State private var exportVM = ExportViewModel()

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical]) {
                    CodeCardView()
                        .frame(
                            width: max(vm.displayWidth, 300),
                            height: max(vm.displayHeight, 200)
                        )
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
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack {
            Text("\(vm.imageWidth) \u{00D7} \(vm.imageHeight) px @ \(Int(settings.exportScale))\u{00D7}")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Copy") {
                Task {
                    await exportVM.copyToClipboard(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: false
                    )
                }
            }
            .disabled(exportVM.isExporting)

            Button("Export PNG") {
                Task {
                    await exportVM.exportPNG(
                        cardView: exportCard,
                        scale: settings.exportScale,
                        isPro: false
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(exportVM.isExporting)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private var exportCard: some View {
        CodeCardView()
            .frame(
                width: max(vm.displayWidth, 300),
                height: max(vm.displayHeight, 200)
            )
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
        .frame(width: 700, height: 500)
}
