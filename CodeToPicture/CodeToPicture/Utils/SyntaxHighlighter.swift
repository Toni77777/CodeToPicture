import AppKit
import JavaScriptCore

@MainActor
final class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()

    private let context: JSContext
    private var colorCache: [String: [String: NSColor]] = [:]

    private init() {
        context = JSContext()!
        if let url = Bundle.main.url(forResource: "highlight.min", withExtension: "js"),
           let js = try? String(contentsOf: url, encoding: .utf8) {
            context.evaluateScript(js)
        }
    }

    // MARK: - Public

    func highlightedHTML(code: String, language: String) -> String {
        runHighlightJS(code: code, language: language)
    }

    func highlight(
        code: String,
        language: String,
        theme: Theme,
        font: NSFont,
        lineSpacing: CGFloat = 0
    ) -> NSAttributedString {
        let html = runHighlightJS(code: code, language: language)
        let colors = themeColors(for: theme)
        let defaultColor = colors["default"] ?? (theme.isDark ? NSColor.white : NSColor.black)
        return buildAttributedString(html: html, font: font, defaultColor: defaultColor, colors: colors, lineSpacing: lineSpacing)
    }

    func highlightToSwiftUI(
        code: String,
        language: String,
        theme: Theme,
        font: NSFont,
        lineSpacing: CGFloat = 0
    ) -> AttributedString {
        let ns = highlight(code: code, language: language, theme: theme, font: font, lineSpacing: lineSpacing)
        return (try? AttributedString(ns, including: \.appKit)) ?? AttributedString(code)
    }

    // MARK: - JavaScript

    private func runHighlightJS(code: String, language: String) -> String {
        let escaped = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let js: String
        if language == "auto" {
            js = "hljs.highlightAuto(`\(escaped)`).value"
        } else {
            js = "(function(){ try { return hljs.highlight(`\(escaped)`, {language: '\(language)'}).value } catch(e) { return hljs.highlightAuto(`\(escaped)`).value } })()"
        }

        return context.evaluateScript(js)?.toString() ?? code
    }

    // MARK: - CSS Parsing

    private func themeColors(for theme: Theme) -> [String: NSColor] {
        if let cached = colorCache[theme.id] { return cached }

        let url = Bundle.main.url(forResource: theme.highlightJSName, withExtension: "min.css")
            ?? Bundle.main.url(forResource: theme.highlightJSName + ".min", withExtension: "css")
            ?? Bundle.main.url(forResource: theme.highlightJSName, withExtension: "css")

        guard let url, let css = try? String(contentsOf: url, encoding: .utf8) else { return [:] }

        var colors: [String: NSColor] = [:]

        // Default text color: .hljs { ... color: #xxx ... }
        let defaultPattern = /\.hljs\s*\{[^}]*?color:\s*(#[0-9a-fA-F]{3,8})/
        if let match = css.firstMatch(of: defaultPattern) {
            colors["default"] = NSColor(hexString: String(match.1))
        }

        // Token colors: .hljs-keyword { color: #xxx }
        // Also handles comma-separated selectors: .hljs-doctag,.hljs-keyword { color: #xxx }
        let tokenPattern = /\.hljs-([\w-]+)\s*[\{,][^}]*?color:\s*(#[0-9a-fA-F]{3,8})/
        for match in css.matches(of: tokenPattern) {
            colors[String(match.1)] = NSColor(hexString: String(match.2))
        }

        // Handle comma selectors more thoroughly
        let blockPattern = /([^{}]+)\{([^}]*)\}/
        for block in css.matches(of: blockPattern) {
            let selectors = String(block.1)
            let body = String(block.2)

            guard let colorMatch = body.firstMatch(of: /color:\s*(#[0-9a-fA-F]{3,8})/) else { continue }
            let color = NSColor(hexString: String(colorMatch.1))

            for selector in selectors.split(separator: ",") {
                let sel = selector.trimmingCharacters(in: .whitespaces)
                let namePattern = /\.hljs-([\w-]+)/
                for nameMatch in sel.matches(of: namePattern) {
                    let key = String(nameMatch.1)
                    if colors[key] == nil {
                        colors[key] = color
                    }
                }
            }
        }

        colorCache[theme.id] = colors
        return colors
    }

    // MARK: - HTML → NSAttributedString

    private func buildAttributedString(
        html: String,
        font: NSFont,
        defaultColor: NSColor,
        colors: [String: NSColor],
        lineSpacing: CGFloat
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var colorStack: [NSColor] = [defaultColor]

        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing

        var i = html.startIndex

        while i < html.endIndex {
            if html[i] == "<" {
                // Find closing >
                guard let tagEnd = html[i...].firstIndex(of: ">") else { break }
                let tag = html[i...tagEnd]

                if tag.hasPrefix("<span") {
                    // Extract class value
                    if let classRange = tag.range(of: "class=\""),
                       let closeQuote = tag[classRange.upperBound...].firstIndex(of: "\"") {
                        let className = String(tag[classRange.upperBound..<closeQuote])
                        let color = resolveColor(className: className, colors: colors, fallback: colorStack.last ?? defaultColor)
                        colorStack.append(color)
                    } else {
                        colorStack.append(colorStack.last ?? defaultColor)
                    }
                } else if tag.hasPrefix("</span") {
                    if colorStack.count > 1 { colorStack.removeLast() }
                }

                i = html.index(after: tagEnd)
                continue
            }

            // Collect text run until next < or end
            var runEnd = html.index(after: i)
            while runEnd < html.endIndex && html[runEnd] != "<" {
                runEnd = html.index(after: runEnd)
            }

            let rawText = String(html[i..<runEnd])
            let decoded = decodeHTMLEntities(rawText)

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: colorStack.last ?? defaultColor,
                .paragraphStyle: style
            ]
            result.append(NSAttributedString(string: decoded, attributes: attrs))

            i = runEnd
        }

        // If empty, return a space with default formatting
        if result.length == 0 {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: defaultColor,
                .paragraphStyle: style
            ]
            result.append(NSAttributedString(string: " ", attributes: attrs))
        }

        return result
    }

    private func resolveColor(className: String, colors: [String: NSColor], fallback: NSColor) -> NSColor {
        // className can be "hljs-keyword" or "hljs-title function_" etc.
        let parts = className.split(separator: " ")
        for part in parts {
            let key = part.hasPrefix("hljs-") ? String(part.dropFirst(5)) : String(part)
            if let color = colors[key] { return color }
        }
        return fallback
    }

    private func decodeHTMLEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}

// MARK: - NSColor hex helper

extension NSColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
