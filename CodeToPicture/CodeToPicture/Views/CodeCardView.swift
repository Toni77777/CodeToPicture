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

                CodePreviewWebView(
                    code: editorVM.code,
                    highlightJSName: themeManager.selectedTheme.highlightJSName,
                    fontSize: settings.fontSize
                )
                .padding(settings.padding)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: settings.cornerRadius))
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
