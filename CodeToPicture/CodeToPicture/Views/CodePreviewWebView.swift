import SwiftUI
import WebKit

struct CodePreviewWebView: NSViewRepresentable {
    var code: String
    var highlightJSName: String
    var fontSize: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let previewOverrides = WKUserScript(
            source: """
            var s = document.createElement('style');
            s.textContent = [
                '#input { display: none !important; }',
                '.hljs { background: transparent !important; }',
                'pre { background: transparent !important; overflow: visible !important; }',
                'pre code.hljs { background: transparent !important; }'
            ].join('');
            document.head.appendChild(s);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        let controller = WKUserContentController()
        controller.addUserScript(previewOverrides)
        controller.add(context.coordinator, name: "bridge")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView

        if let htmlURL = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let c = context.coordinator
        c.pendingCode = code
        c.pendingTheme = highlightJSName
        c.pendingFontSize = fontSize

        guard c.isReady else { return }
        c.applyPendingState(to: webView)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var isReady = false

        var lastCode = ""
        var lastTheme = ""
        var lastFontSize: Double = 0

        var pendingCode = ""
        var pendingTheme = ""
        var pendingFontSize: Double = 14

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: String],
                  body["type"] == "ready",
                  let webView else { return }

            isReady = true
            applyPendingState(to: webView)
        }

        func applyPendingState(to webView: WKWebView) {
            if pendingTheme != lastTheme {
                lastTheme = pendingTheme
                webView.evaluateJavaScript("applyTheme('\(pendingTheme)');", completionHandler: nil)
            }
            if pendingFontSize != lastFontSize {
                lastFontSize = pendingFontSize
                webView.evaluateJavaScript("setFontSize(\(pendingFontSize));", completionHandler: nil)
            }
            if pendingCode != lastCode {
                lastCode = pendingCode
                let escaped = pendingCode
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                webView.evaluateJavaScript("setCode(`\(escaped)`);", completionHandler: nil)
            }
        }
    }
}
