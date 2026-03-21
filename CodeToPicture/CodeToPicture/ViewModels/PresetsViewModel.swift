import Foundation

@Observable
@MainActor
final class PresetsViewModel {
    let builtInPresets: [SocialPreset] = [
        SocialPreset(id: "twitter",      name: "Twitter",   symbolName: "bird",                                    aspectRatio: 16/9,  padding: 40, isBuiltIn: true),
        SocialPreset(id: "instagram",    name: "Instagram", symbolName: "camera",                                  aspectRatio: 1,     padding: 32, isBuiltIn: true),
        SocialPreset(id: "linkedin",     name: "LinkedIn",  symbolName: "network",                                 aspectRatio: 1.91,  padding: 48, isBuiltIn: true),
        SocialPreset(id: "github",       name: "GitHub",    symbolName: "chevron.left.forwardslash.chevron.right", aspectRatio: nil,    padding: 24, isBuiltIn: true),
        SocialPreset(id: "presentation", name: "Slide",     symbolName: "rectangle.on.rectangle",                  aspectRatio: 16/9,  padding: 64, isBuiltIn: true),
    ]

    var userPresets: [SocialPreset] = []
    var showSaveSheet: Bool = false
    var newPresetName: String = ""

    init() {
        loadUserPresets()
    }

    func apply(_ preset: SocialPreset, to settings: AppSettings) {
        settings.padding = preset.padding
        if let ar = preset.aspectRatio {
            settings.aspectRatio = ar
        }
    }

    func saveCurrentAsPreset(settings: AppSettings) {
        guard userPresets.count < 10, !newPresetName.isEmpty else { return }
        let preset = SocialPreset(
            id: UUID().uuidString,
            name: newPresetName,
            symbolName: "star",
            aspectRatio: settings.aspectRatio,
            padding: settings.padding,
            isBuiltIn: false
        )
        userPresets.append(preset)
        newPresetName = ""
        persistUserPresets()
    }

    func deleteUserPreset(_ preset: SocialPreset) {
        userPresets.removeAll { $0.id == preset.id }
        persistUserPresets()
    }

    private func loadUserPresets() {
        guard let data = UserDefaults.standard.data(forKey: "userPresets"),
              let decoded = try? JSONDecoder().decode([SocialPreset].self, from: data)
        else { return }
        userPresets = decoded
    }

    private func persistUserPresets() {
        guard let data = try? JSONEncoder().encode(userPresets) else { return }
        UserDefaults.standard.set(data, forKey: "userPresets")
    }
}
