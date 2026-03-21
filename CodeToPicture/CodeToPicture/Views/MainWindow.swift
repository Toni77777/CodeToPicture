import SwiftUI

struct MainWindow: View {
    @Environment(EditorViewModel.self) private var editorVM

    var body: some View {
        NavigationSplitView {
            SettingsPanel()
                .navigationSplitViewColumnWidth(280)
        } detail: {
            HSplitView {
                EditorView()
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                PreviewView()
            }
        }
    }
}

#Preview {
    MainWindow()
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(PurchaseManager())
        .environment(EditorViewModel())
}
