import SwiftUI

struct MainWindow: View {
    var body: some View {
        NavigationSplitView {
            SettingsPanel()
                .navigationSplitViewColumnWidth(280)
        } detail: {
            PreviewView()
        }
    }
}

#Preview {
    MainWindow()
        .environment(AppSettings())
        .environment(ThemeManager())
}
