import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class ExportViewModel {
    var isExporting: Bool = false
    var statusMessage: String = ""
    var showProSheet: Bool = false

    private let manager = ExportManager()
    private var dismissTask: Task<Void, Never>?

    // MARK: - PNG

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

    // MARK: - PDF

    func exportPDFFile(cardView: sending some View, size: CGSize, isPro: Bool) async {
        guard isPro else {
            showProSheet = true
            return
        }

        isExporting = true
        defer { isExporting = false }

        let data = await manager.exportPDF(view: cardView, size: size)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "snapshot.pdf"

        guard let window = NSApp.keyWindow else { return }
        let response = await panel.beginSheetModal(for: window)

        if response == .OK, let url = panel.url {
            try? data.write(to: url)
            showStatus("Exported PDF!")
        }
    }

    // MARK: - SVG

    func exportSVGFile(
        code: String,
        language: String,
        theme: Theme,
        settings: AppSettings,
        cardWidth: Double,
        cardHeight: Double,
        isPro: Bool
    ) async {
        guard isPro else {
            showProSheet = true
            return
        }

        isExporting = true
        defer { isExporting = false }

        let highlightedHTML = SyntaxHighlighter.shared.highlightedHTML(code: code, language: language)

        let svg = await manager.exportSVG(
            highlightedHTML: highlightedHTML,
            themeHighlightJSName: theme.highlightJSName,
            cardBackgroundHex: theme.backgroundColorHex,
            canvasBackground: settings.canvasBackground,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            canvasPadding: settings.canvasPadding,
            canvasCornerRadius: settings.canvasCornerRadius,
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
            padding: settings.padding,
            cornerRadius: settings.cornerRadius,
            showWindowFrame: settings.showWindowFrame,
            windowFrameStyle: settings.windowFrameStyle
        )

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.svg]
        panel.nameFieldStringValue = "snapshot.svg"

        guard let window = NSApp.keyWindow else { return }
        let response = await panel.beginSheetModal(for: window)

        if response == .OK, let url = panel.url,
           let data = svg.data(using: .utf8) {
            try? data.write(to: url)
            showStatus("Exported SVG!")
        }
    }

    // MARK: - Status

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
