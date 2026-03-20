import Foundation

@Observable
@MainActor
final class ThemeManager {
    private(set) var builtInThemes: [Theme] = []

    init() {
        builtInThemes = Self.loadBuiltInThemes()
    }

    func theme(for id: String) -> Theme? {
        builtInThemes.first { $0.id == id }
    }

    private static func loadBuiltInThemes() -> [Theme] {
        let fileNames = [
            "catppuccin-mocha",
            "dracula",
            "monokai",
            "nord",
            "one-dark",
            "solarized-dark"
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
