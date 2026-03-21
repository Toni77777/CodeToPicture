import SwiftUI

@Observable
@MainActor
final class ThemeManager {
    var themes: [Theme] = []

    var selectedThemeID: String = "dracula" {
        didSet { UserDefaults.standard.set(selectedThemeID, forKey: "selectedThemeID") }
    }

    var selectedTheme: Theme {
        themes.first { $0.id == selectedThemeID } ?? themes[0]
    }

    var freeThemes: [Theme] { themes.filter { !$0.isPro } }
    var proThemes: [Theme] { themes.filter { $0.isPro } }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedThemeID") {
            selectedThemeID = saved
        }
        let free = Self.loadThemes(names: [
            "dracula", "github-dark", "github-light", "monokai", "nord", "one-dark"
        ])
        let pro = Self.loadThemes(names: [
            "atom-one-dark", "ayu-dark", "catppuccin-mocha", "cyberpunk", "dracula-pro",
            "everforest-dark", "gruvbox-dark", "horizon", "material-dark", "material-ocean",
            "night-owl", "palenight", "panda", "rose-pine", "shades-of-purple",
            "solarized-dark", "tokyo-night", "vs-dark", "winter-is-coming-dark", "github-dimmed-dark",
            "ayu-light", "catppuccin-latte", "everforest-light", "gruvbox-light",
            "material-light", "minimal-light", "rose-pine-dawn", "solarized-light",
            "vs-light", "xcode-light", "atom-one-light", "notion-light", "paper",
            "soft-era", "winter-is-coming-light", "quiet-light", "parchment",
            "alabaster", "github-dimmed-light", "default-light"
        ])
        themes = free + pro
    }

    func applyTheme(_ theme: Theme, isPro: Bool, onProRequired: () -> Void) {
        if theme.isPro && !isPro {
            onProRequired()
            return
        }
        selectedThemeID = theme.id
    }

    func cssURL(for theme: Theme) -> URL? {
        Bundle.main.url(forResource: theme.highlightJSName, withExtension: "min.css")
            ?? Bundle.main.url(forResource: theme.highlightJSName, withExtension: "css")
    }

    private static func loadThemes(names: [String]) -> [Theme] {
        names.compactMap { name in
            let url = Bundle.main.url(forResource: name, withExtension: "json",
                                      subdirectory: "Themes/Resources/Themes/pro")
                   ?? Bundle.main.url(forResource: name, withExtension: "json",
                                      subdirectory: "Themes/Resources/Themes/free")
                   ?? Bundle.main.url(forResource: name, withExtension: "json")
            guard let url, let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(Theme.self, from: data)
        }
    }
}
