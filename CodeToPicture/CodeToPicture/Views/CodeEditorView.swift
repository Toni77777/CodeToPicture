import SwiftUI
import WebKit

struct CodeEditorView: NSViewRepresentable {
    @Environment(EditorViewModel.self) private var vm
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "bridge")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator

        context.coordinator.vm = vm
        context.coordinator.webView = webView
        vm.register(webView: webView)

        if let htmlURL = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.vm = vm

        guard coordinator.isReady else { return }

        if settings.fontSize != coordinator.lastFontSize {
            coordinator.lastFontSize = settings.fontSize
            vm.setFontSize(settings.fontSize)
        }

        if settings.selectedThemeID != coordinator.lastThemeID {
            coordinator.lastThemeID = settings.selectedThemeID
            if let theme = themeManager.theme(for: settings.selectedThemeID) {
                vm.applyTheme(theme)
            }
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var vm: EditorViewModel?
        weak var webView: WKWebView?
        var isReady = false
        var lastFontSize: Double = 0
        var lastThemeID: String = ""

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Ready signal comes from JS bridge message
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: String],
                  let type = body["type"],
                  let payload = body["payload"] else { return }

            guard let vm else { return }

            switch type {
            case "ready":
                isReady = true
                vm.isReady = true
                vm.setFontSize(lastFontSize > 0 ? lastFontSize : 14)
            case "codeChanged":
                vm.code = payload
            default:
                break
            }
        }
    }
}
