import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class ExportViewModel {
    var isExporting: Bool = false
    var statusMessage: String = ""

    private let manager = ExportManager()
    private var dismissTask: Task<Void, Never>?

    func exportPNG(cardView: sending some View, scale: CGFloat, isPro: Bool) async {
        isExporting = true
        defer { isExporting = false }

        let image = await manager.renderImage(view: cardView, scale: scale)
        let stamped = await manager.addWatermark(to: image, isPro: isPro)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "snapshot.png"

        guard let window = NSApp.keyWindow else { return }
        let response = await panel.beginSheetModal(for: window)

        if response == .OK, let url = panel.url,
           let data = await manager.pngData(from: stamped) {
            try? data.write(to: url)
            showStatus("Exported!")
        }
    }

    func copyToClipboard(cardView: sending some View, scale: CGFloat, isPro: Bool) async {
        isExporting = true
        defer { isExporting = false }

        let image = await manager.renderImage(view: cardView, scale: scale)
        let stamped = await manager.addWatermark(to: image, isPro: isPro)

        if let data = await manager.pngData(from: stamped) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setData(data, forType: .png)
            showStatus("Copied!")
        }
    }

    private func showStatus(_ msg: String) {
        statusMessage = msg
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            statusMessage = ""
        }
    }
}
