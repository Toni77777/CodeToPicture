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
        cardBackgroundHex: String,
        canvasBackground: CanvasBackground,
        cardWidth: Double,
        cardHeight: Double,
        canvasPadding: Double,
        canvasCornerRadius: Double,
        fontSize: Double,
        fontFamily: String,
        padding: Double,
        cornerRadius: Double,
        showWindowFrame: Bool,
        windowFrameStyle: String
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

        let totalWidth = cardWidth + canvasPadding * 2
        let totalHeight = cardHeight + canvasPadding * 2
        let cardX = canvasPadding
        let cardY = canvasPadding

        let lineHeight = fontSize * 1.6
        let frameHeight: Double = showWindowFrame ? 24 : 0

        var defs = ""
        let canvasFill = svgFill(for: canvasBackground, defsOut: &defs, gradientID: "canvasBg")

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(Int(totalWidth))\" height=\"\(Int(totalHeight))\" xml:space=\"preserve\">\n"

        if !defs.isEmpty {
            svg += "<defs>\(defs)</defs>\n"
        }

        // Canvas background
        if canvasFill != "none" {
            svg += "<rect width=\"\(Int(totalWidth))\" height=\"\(Int(totalHeight))\" fill=\"\(canvasFill)\" rx=\"\(Int(canvasCornerRadius))\"/>\n"
        }

        // Card background
        svg += "<rect x=\"\(formatCoord(cardX))\" y=\"\(formatCoord(cardY))\" width=\"\(formatCoord(cardWidth))\" height=\"\(formatCoord(cardHeight))\" fill=\"\(cardBackgroundHex)\" rx=\"\(Int(cornerRadius))\"/>\n"

        // Window frame (relative to card)
        if showWindowFrame {
            svg += windowFrameSVG(style: windowFrameStyle, cardOriginX: cardX, cardOriginY: cardY)
        }

        // Code text
        let textX = cardX + padding
        let textStartY = cardY + frameHeight + padding + fontSize

        for (index, lineTokens) in lines.enumerated() {
            let y = textStartY + Double(index) * lineHeight
            svg += "<text x=\"\(formatCoord(textX))\" y=\"\(formatCoord(y))\" font-family=\"\(escapeXML(fontFamily)), monospace\" font-size=\"\(Int(fontSize))\">"
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

    // MARK: - SVG Canvas Background

    private func svgFill(for background: CanvasBackground, defsOut: inout String, gradientID: String) -> String {
        switch background {
        case .none:
            return "none"

        case .solid(let hex):
            return hex

        case .linearGradient(let stops, let angle):
            let radians = angle * .pi / 180
            let startX = 0.5 + 0.5 * cos(radians)
            let startY = 0.5 + 0.5 * sin(radians)
            let endX = 0.5 - 0.5 * cos(radians)
            let endY = 0.5 - 0.5 * sin(radians)

            var def = "<linearGradient id=\"\(gradientID)\" x1=\"\(formatPercent(startX))\" y1=\"\(formatPercent(startY))\" x2=\"\(formatPercent(endX))\" y2=\"\(formatPercent(endY))\">"
            for stop in stops {
                def += "<stop offset=\"\(formatPercent(stop.position))\" stop-color=\"\(stop.colorHex)\"/>"
            }
            def += "</linearGradient>"
            defsOut += def
            return "url(#\(gradientID))"

        case .radialGradient(let stops, let centerX, let centerY):
            var def = "<radialGradient id=\"\(gradientID)\" cx=\"\(formatPercent(centerX))\" cy=\"\(formatPercent(centerY))\" r=\"70%\">"
            for stop in stops {
                def += "<stop offset=\"\(formatPercent(stop.position))\" stop-color=\"\(stop.colorHex)\"/>"
            }
            def += "</radialGradient>"
            defsOut += def
            return "url(#\(gradientID))"

        case .meshGradient(let colors, _):
            // SVG has no native mesh; approximate with a diagonal linear gradient through all colors
            guard !colors.isEmpty else { return "none" }
            if colors.count == 1 { return colors[0] }

            var def = "<linearGradient id=\"\(gradientID)\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\">"
            for (i, color) in colors.enumerated() {
                let pos = Double(i) / Double(colors.count - 1)
                def += "<stop offset=\"\(formatPercent(pos))\" stop-color=\"\(color)\"/>"
            }
            def += "</linearGradient>"
            defsOut += def
            return "url(#\(gradientID))"
        }
    }

    // MARK: - SVG Window Frame

    private func windowFrameSVG(style: String, cardOriginX: Double, cardOriginY: Double) -> String {
        if style == "none" { return "" }

        let centerY = cardOriginY + 18
        let firstCX = cardOriginX + 18

        let colors: [String]
        switch style {
        case "chrome", "arc":
            colors = ["#ffffff40", "#ffffff40", "#ffffff40"]
        default:
            colors = ["#FF5F57", "#FEBC2E", "#28C840"]
        }

        var svg = ""
        for (i, color) in colors.enumerated() {
            let cx = firstCX + Double(i) * 20
            svg += "<circle cx=\"\(formatCoord(cx))\" cy=\"\(formatCoord(centerY))\" r=\"6\" fill=\"\(color)\"/>\n"
        }
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

        let url = Bundle.main.url(forResource: hlName, withExtension: "min.css")
            ?? Bundle.main.url(forResource: hlName + ".min", withExtension: "css")
            ?? Bundle.main.url(forResource: hlName, withExtension: "css")

        guard let url, let css = try? String(contentsOf: url, encoding: .utf8) else {
            return colors
        }

        // Default text color: .hljs { ... color: #xxx ... }
        let defaultPattern = /\.hljs\s*\{[^}]*?color:\s*(#[0-9a-fA-F]{3,8})/
        if let match = css.firstMatch(of: defaultPattern) {
            colors["default"] = String(match.1)
        }

        // Walk every CSS block and assign the block's color to each comma-separated .hljs-* selector
        let blockPattern = /([^{}]+)\{([^}]*)\}/
        for block in css.matches(of: blockPattern) {
            let selectors = String(block.1)
            let body = String(block.2)

            guard let colorMatch = body.firstMatch(of: /color:\s*(#[0-9a-fA-F]{3,8})/) else { continue }
            let color = String(colorMatch.1)

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

        return colors
    }

    private func formatCoord(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func formatPercent(_ fraction: Double) -> String {
        String(format: "%.2f%%", fraction * 100)
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
