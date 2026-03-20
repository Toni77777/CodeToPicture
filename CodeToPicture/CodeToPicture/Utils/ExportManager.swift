import AppKit

actor ExportManager {
    func renderImage(from view: NSView, scale: Double) async throws -> NSImage? {
        // TODO: Off-main-thread image rendering
        nil
    }

    func savePNG(_ image: NSImage, to url: URL) async throws {
        // TODO: Write PNG data to disk
    }

    func copyToClipboard(_ image: NSImage) async {
        // TODO: Copy image to NSPasteboard
    }
}
