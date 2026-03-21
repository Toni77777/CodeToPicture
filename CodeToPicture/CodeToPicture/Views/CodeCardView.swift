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

                Text(editorVM.code.isEmpty ? " " : editorVM.code)
                    .font(.system(size: settings.fontSize, design: .monospaced))
                    .foregroundStyle(Color(hex: themeManager.selectedTheme.isDark ? "#f8f8f2" : "#24292e"))
                    .lineSpacing(settings.fontSize * 0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
