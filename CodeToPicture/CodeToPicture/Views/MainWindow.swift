import SwiftUI

struct MainWindow: View {
    @State private var editorVM = EditorViewModel()

    var body: some View {
        NavigationSplitView {
            SettingsPanel()
                .navigationSplitViewColumnWidth(280)
        } detail: {
            HSplitView {
                EditorView()
                PreviewView()
            }
        }
        .environment(editorVM)
    }
}

#Preview {
    MainWindow()
        .environment(AppSettings())
        .environment(ThemeManager())
}
