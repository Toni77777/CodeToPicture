import SwiftUI
import WebKit

@Observable
@MainActor
final class EditorViewModel {
    var code: String = ""
    var language: String = "auto"
    var isReady: Bool = false

    private weak var webView: WKWebView?

    func register(webView: WKWebView) {
        self.webView = webView
    }

    func applyTheme(_ theme: Theme) {
        let js = """
        applyTheme({
            backgroundColor: "\(theme.backgroundColor)",
            foregroundColor: "\(theme.foregroundColor)",
            selectionColor: "\(theme.selectionColor)",
            keywords: "\(theme.keywords)",
            strings: "\(theme.strings)",
            comments: "\(theme.comments)",
            functions: "\(theme.functions)",
            types: "\(theme.types)",
            numbers: "\(theme.numbers)"
        });
        """
        evaluateJS(js)
    }

    func setLanguage(_ lang: String) {
        language = lang
        evaluateJS("setLanguage('\(lang)');")
    }

    func setFontSize(_ size: Double) {
        evaluateJS("setFontSize(\(size));")
    }

    func setCode(_ code: String) {
        let escaped = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        evaluateJS("setCode(`\(escaped)`);")
    }

    private func evaluateJS(_ js: String) {
        webView?.evaluateJavaScript(js) { _, error in
            if let error {
                print("[EditorVM] JS error: \(error.localizedDescription)")
            }
        }
    }
}
