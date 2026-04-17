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

    // MARK: - PDF

    nonisolated func exportPDF<V: View>(view: sending V, size: CGSize) async -> Data {
        await MainActor.run {
            let hosting = NSHostingView(rootView: AnyView(view))
            hosting.frame = CGRect(origin: .zero, size: size)
            hosting.layoutSubtreeIfNeeded()
            return hosting.dataWithPDF(inside: hosting.bounds)
        }
    }

    // MARK: - SVG

    func exportSVG(
        highlightedHTML: String,
        themeHighlightJSName: String,
        backgroundColorHex: String,
        fontSize: Double,
        fontFamily: String,
        padding: Double,
        cornerRadius: Double,
        showWindowFrame: Bool
    ) -> String {
        let tokenColors = parseThemeColors(hlName: themeHighlightJSName)
        let defaultColor = tokenColors["default"] ?? "#f8f8f2"

        let tokens = parseHTMLTokens(html: highlightedHTML, colors: tokenColors, defaultColor: defaultColor)

        // Split tokens into lines, preserving empty lines
        var lines: [[(text: String, color: String)]] = [[]]
        for token in tokens {
            let parts = token.text.components(separatedBy: "\n")
            for (i, part) in parts.enumerated() {
                if i > 0 { lines.append([]) }
                if !part.isEmpty {
                    lines[lines.count - 1].append((text: part, color: token.color))
                }
            }
        }

        let lineCount = max(lines.count, 1)
        let lineHeight = fontSize * 1.6
        let charWidth = fontSize * 0.6
        let maxLineLength = lines.map { $0.reduce(0) { $0 + $1.text.count } }.max() ?? 1
        let estimatedWidth = Double(maxLineLength) * charWidth

        let frameOffset: Double = showWindowFrame ? 40 : 0
        let w = padding * 2 + max(estimatedWidth, 200)
        let h = padding * 2 + Double(lineCount) * lineHeight + frameOffset

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(Int(w))\" height=\"\(Int(h))\" xml:space=\"preserve\">\n"
        svg += "<rect width=\"100%\" height=\"100%\" fill=\"\(backgroundColorHex)\" rx=\"\(Int(cornerRadius))\"/>\n"

        if showWindowFrame {
            svg += "<circle cx=\"\(Int(padding + 8))\" cy=\"22\" r=\"6\" fill=\"#FF5F57\"/>\n"
            svg += "<circle cx=\"\(Int(padding + 28))\" cy=\"22\" r=\"6\" fill=\"#FEBC2E\"/>\n"
            svg += "<circle cx=\"\(Int(padding + 48))\" cy=\"22\" r=\"6\" fill=\"#28C840\"/>\n"
        }

        let textX = padding
        let textStartY = padding + frameOffset + fontSize

        for (index, lineTokens) in lines.enumerated() {
            let y = textStartY + Double(index) * lineHeight
            svg += "<text x=\"\(Int(textX))\" y=\"\(Int(y))\" font-family=\"\(fontFamily), monospace\" font-size=\"\(Int(fontSize))\">"
            if lineTokens.isEmpty {
                svg += " "
            } else {
                for token in lineTokens {
                    svg += "<tspan fill=\"\(token.color)\">\(escapeXML(token.text))</tspan>"
                }
            }
            svg += "</text>\n"
        }

        svg += "</svg>"
        return svg
    }

    // MARK: - SVG Helpers

    private struct SVGToken {
        let text: String
        let color: String
    }

    private func parseHTMLTokens(html: String, colors: [String: String], defaultColor: String) -> [SVGToken] {
        var tokens: [SVGToken] = []
        var colorStack = [defaultColor]
        var i = html.startIndex

        while i < html.endIndex {
            if html[i] == "<" {
                guard let tagEnd = html[i...].firstIndex(of: ">") else { break }
                let tag = String(html[i...tagEnd])

                if tag.hasPrefix("<span") {
                    if let classRange = tag.range(of: "class=\""),
                       let closeQuote = tag[classRange.upperBound...].firstIndex(of: "\"") {
                        let className = String(tag[classRange.upperBound..<closeQuote])
                        let color = resolveTokenColor(className: className, colors: colors, fallback: colorStack.last ?? defaultColor)
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

            var runEnd = html.index(after: i)
            while runEnd < html.endIndex && html[runEnd] != "<" {
                runEnd = html.index(after: runEnd)
            }

            let rawText = String(html[i..<runEnd])
            let decoded = decodeHTMLEntities(rawText)
            if !decoded.isEmpty {
                tokens.append(SVGToken(text: decoded, color: colorStack.last ?? defaultColor))
            }
            i = runEnd
        }

        return tokens
    }

    private func resolveTokenColor(className: String, colors: [String: String], fallback: String) -> String {
        let parts = className.split(separator: " ")
        for part in parts {
            let key = part.hasPrefix("hljs-") ? String(part.dropFirst(5)) : String(part)
            if let color = colors[key] { return color }
        }
        return fallback
    }

    private func decodeHTMLEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
    }

    private func parseThemeColors(hlName: String) -> [String: String] {
        var colors: [String: String] = [:]

        let url = Bundle.main.url(forResource: hlName, withExtension: "css")
            ?? Bundle.main.url(forResource: hlName + ".min", withExtension: "css")

        guard let url, let css = try? String(contentsOf: url, encoding: .utf8) else {
            return colors
        }

        // Extract default text color from .hljs{...color:#xxx...}
        let defaultPattern = /\.hljs\s*\{[^}]*color:\s*(#[0-9a-fA-F]{3,8})/
        if let match = css.firstMatch(of: defaultPattern) {
            colors["default"] = String(match.1)
        }

        // Extract token colors: .hljs-keyword{color:#ff79c6}
        let tokenPattern = /\.hljs-([\w-]+)\s*[\{,][^}]*?color:\s*(#[0-9a-fA-F]{3,8})/
        for match in css.matches(of: tokenPattern) {
            colors[String(match.1)] = String(match.2)
        }

        return colors
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
