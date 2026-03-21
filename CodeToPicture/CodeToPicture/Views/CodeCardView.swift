import SwiftUI

struct CodeCardView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(EditorViewModel.self) private var editorVM
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .fill(Color(hex: themeManager.selectedTheme.backgroundColorHex))
                .shadow(radius: 20, y: 8)

            VStack(alignment: .leading, spacing: 0) {
                if settings.showWindowFrame {
                    WindowFrameView()
                        .padding([.top, .leading], 12)
                }

                Text(highlightedCode)
                    .lineSpacing(settings.fontSize * 0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(settings.padding)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: settings.cornerRadius))
    }

    private var highlightedCode: AttributedString {
        let code = editorVM.code.isEmpty ? " " : editorVM.code
        let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        return SyntaxHighlighter.shared.highlightToSwiftUI(
            code: code,
            language: editorVM.language,
            theme: themeManager.selectedTheme,
            font: font,
            lineSpacing: settings.fontSize * 0.6
        )
    }
}

#Preview {
    CodeCardView()
        .environment(AppSettings())
        .environment(EditorViewModel())
        .environment(ThemeManager())
        .frame(width: 600, height: 400)
        .padding(40)
}
