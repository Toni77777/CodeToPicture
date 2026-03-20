import SwiftUI

struct EditorView: NSViewRepresentable {
    @Environment(AppSettings.self) private var settings

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.font = .monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
    }
}

#Preview {
    EditorView()
        .environment(AppSettings())
}
