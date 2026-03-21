import SwiftUI

@Observable
@MainActor
final class BatchExportViewModel {
    var items: [BatchExportItem] = []
    var isExporting: Bool = false
    var progress: Int = 0
    var outputFolderURL: URL? = nil

    private static let extensionToLanguage: [String: String] = [
        "swift": "swift", "py": "python", "js": "javascript", "ts": "typescript",
        "kt": "kotlin", "rs": "rust", "go": "go", "rb": "ruby",
        "java": "java", "cpp": "cpp", "cs": "csharp", "m": "objectivec",
        "c": "c", "h": "c", "php": "php", "scala": "scala",
        "sql": "sql", "html": "html", "css": "css", "sh": "shell",
        "json": "json", "yaml": "yaml", "yml": "yaml"
    ]

    func addFiles(_ urls: [URL]) {
        for url in urls {
            let lang = Self.extensionToLanguage[url.pathExtension.lowercased()] ?? "auto"
            let item = BatchExportItem(
                fileURL: url,
                filename: url.deletingPathExtension().lastPathComponent,
                detectedLanguage: lang
            )
            items.append(item)
        }
    }

    func removeItem(_ item: BatchExportItem) {
        items.removeAll { $0.id == item.id }
    }

    func startExport(settings: AppSettings, themeManager: ThemeManager, isPro: Bool) async {
        guard !items.isEmpty, let folder = outputFolderURL else { return }
        isExporting = true
        progress = 0

        let manager = ExportManager()

        for i in items.indices {
            items[i].status = .processing
            do {
                let code = try String(contentsOf: items[i].fileURL, encoding: .utf8)

                let tempEditor = EditorViewModel()
                tempEditor.code = code
                tempEditor.language = items[i].detectedLanguage

                let cardView = ZStack {
                    CanvasBackgroundView(background: settings.canvasBackground)
                    CodeCardView()
                }
                .environment(settings)
                .environment(tempEditor)
                .environment(themeManager)

                let renderer = ImageRenderer(content: cardView)
                renderer.scale = settings.exportScale
                let image = renderer.nsImage ?? NSImage()
                let stamped = await manager.addWatermark(to: image, isPro: isPro)
                let dest = folder.appendingPathComponent(items[i].filename + ".png")
                if let data = await manager.pngData(from: stamped) {
                    try data.write(to: dest)
                }
                items[i].status = .done
            } catch {
                items[i].status = .failed(error.localizedDescription)
            }
            progress += 1
        }

        isExporting = false
    }
}
