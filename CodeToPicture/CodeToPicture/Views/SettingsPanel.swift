import SwiftUI

struct SettingsPanel: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme")
                .font(.headline)

            ThemePicker()

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SettingsPanel()
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(EditorViewModel())
        .frame(width: 280, height: 400)
}
