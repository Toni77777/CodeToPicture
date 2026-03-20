import SwiftUI

@main
struct SnapCodeApp: App {
    @State private var settings = AppSettings()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            MainWindow()
        }
        .environment(settings)
        .environment(themeManager)
    }
}
