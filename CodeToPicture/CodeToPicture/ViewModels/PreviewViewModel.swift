import Foundation

@Observable
@MainActor
final class PreviewViewModel {
    var imageWidth: Int = 0
    var imageHeight: Int = 0
    var statusMessage: String = ""

    var displayWidth: CGFloat = 600
    var displayHeight: CGFloat = 400

    private var dismissTask: Task<Void, Never>?

    func computeDimensions(containerWidth: CGFloat, code: String, settings: AppSettings) {
        let lineCount = max(code.components(separatedBy: "\n").count, 1)
        let lineHeight = settings.fontSize * 1.5
        let contentHeight = Double(lineCount) * lineHeight
        let estimatedHeight = contentHeight + settings.padding * 2
            + (settings.showWindowFrame ? 40 : 0)

        displayWidth = containerWidth
        displayHeight = estimatedHeight
        imageWidth = Int(containerWidth * settings.exportScale)
        imageHeight = Int(estimatedHeight * settings.exportScale)
    }

    func showStatus(_ msg: String) {
        statusMessage = msg
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            statusMessage = ""
        }
    }
}
