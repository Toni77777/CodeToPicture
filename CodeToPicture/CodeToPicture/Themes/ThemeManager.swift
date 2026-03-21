import SwiftUI

@Observable
@MainActor
final class ThemeManager {
    var themes: [Theme] = []

    @ObservationIgnored
    @AppStorage("selectedThemeID") private var selectedThemeID: String = "dracula"

    var selectedTheme: Theme {
        themes.first { $0.id == selectedThemeID } ?? themes[0]
    }

    init() {
        themes = Self.loadBuiltInThemes()
    }

    func applyTheme(_ theme: Theme, editorVM: EditorViewModel) {
        selectedThemeID = theme.id
    }

    private static func loadBuiltInThemes() -> [Theme] {
        let fileNames = [
            "dracula",
            "github-dark",
            "github-light",
            "monokai",
            "nord",
            "one-dark"
        ]

        return fileNames.compactMap { name in
            let url = Bundle.main.url(forResource: name, withExtension: "json",
                                      subdirectory: "Themes/Resources/Themes/free")
                   ?? Bundle.main.url(forResource: name, withExtension: "json")
            guard let url, let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(Theme.self, from: data)
        }
    }
}
