import SwiftUI

struct SettingsPanel: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Text("Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsPanel()
        .environment(AppSettings())
        .environment(ThemeManager())
}
