import SwiftUI

@main
struct SnapCodeApp: App {
    @State private var settings = AppSettings()
    @State private var themeManager = ThemeManager()
    @State private var purchaseManager = PurchaseManager()
    @State private var editorVM = EditorViewModel()
    @State private var menuBarManager = MenuBarManager()

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environment(editorVM)
                .environment(menuBarManager)
        }
        .environment(settings)
        .environment(themeManager)
        .environment(purchaseManager)
    }
}
