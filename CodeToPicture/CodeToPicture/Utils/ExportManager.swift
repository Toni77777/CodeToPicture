import AppKit
import SwiftUI

actor ExportManager {

    // MARK: - Render

    nonisolated func renderImage<V: View>(view: sending V, scale: CGFloat) async -> NSImage {
        await MainActor.run {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            return renderer.nsImage ?? NSImage()
        }
    }

    // MARK: - Watermark

    func addWatermark(to image: NSImage, isPro: Bool) -> NSImage {
        guard !isPro else { return image }

        let size = image.size
        return NSImage(size: size, flipped: false) { rect in
            image.draw(in: rect)

            let text = "Made with SnapCode" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "SF Mono", size: 10)
                    ?? NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.6)
            ]
            let textSize = text.size(withAttributes: attrs)
            let pill = CGRect(
                x: rect.width - textSize.width - 24,
                y: 8,
                width: textSize.width + 16,
                height: textSize.height + 8
            )
            NSColor.black.withAlphaComponent(0.45).setFill()
            NSBezierPath(roundedRect: pill, xRadius: 6, yRadius: 6).fill()
            text.draw(
                at: CGPoint(x: pill.minX + 8, y: pill.minY + 4),
                withAttributes: attrs
            )
            return true
        }
    }

    // MARK: - PNG

    func pngData(from image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(
            forProposedRect: nil, context: nil, hints: nil
        ) else { return nil }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = image.size
        return rep.representation(using: .png, properties: [:])
    }
}
