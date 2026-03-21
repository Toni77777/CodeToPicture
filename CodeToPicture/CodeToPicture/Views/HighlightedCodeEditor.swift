import SwiftUI
import AppKit

struct HighlightedCodeEditor: NSViewRepresentable {
    @Binding var code: String
    let language: String
    let theme: Theme
    let fontSize: Double
    let fontFamily: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor(hexString: theme.backgroundColorHex)
        textView.insertionPointColor = theme.isDark ? .white : .black
        textView.textContainerInset = NSSize(width: 8, height: 8)

        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scrollView.documentView = textView

        // Initial highlight
        applyHighlighting(to: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }

        // Update background + insertion point
        textView.backgroundColor = NSColor(hexString: theme.backgroundColorHex)
        textView.insertionPointColor = theme.isDark ? .white : .black

        // Only update text if it changed externally
        if textView.string != code {
            let selection = textView.selectedRange()
            applyHighlighting(to: textView)
            let safeLoc = min(selection.location, textView.string.count)
            let safeLen = min(selection.length, textView.string.count - safeLoc)
            textView.setSelectedRange(NSRange(location: safeLoc, length: safeLen))
        } else {
            // Theme/font changed, re-highlight in place
            applyHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func applyHighlighting(to textView: NSTextView) {
        let font = resolveFont()
        let highlighted = SyntaxHighlighter.shared.highlight(
            code: code.isEmpty ? " " : code,
            language: language,
            theme: theme,
            font: font
        )

        let selection = textView.selectedRange()
        let scroll = textView.enclosingScrollView?.contentView.bounds.origin

        textView.textStorage?.setAttributedString(highlighted)

        // Restore cursor
        let safeLoc = min(selection.location, textView.string.count)
        let safeLen = min(selection.length, textView.string.count - safeLoc)
        textView.setSelectedRange(NSRange(location: safeLoc, length: safeLen))

        // Restore scroll
        if let scroll {
            textView.enclosingScrollView?.contentView.scroll(to: scroll)
        }
    }

    private func resolveFont() -> NSFont {
        NSFont(name: fontFamily, size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedCodeEditor
        var isUpdating = false
        weak var textView: NSTextView?
        private var rehighlightTask: Task<Void, Never>?

        init(parent: HighlightedCodeEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            parent.code = textView.string

            // Debounced re-highlight
            rehighlightTask?.cancel()
            rehighlightTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, let self, let tv = self.textView else { return }
                self.isUpdating = true
                self.parent.applyHighlighting(to: tv)
                self.isUpdating = false
            }
        }
    }
}
