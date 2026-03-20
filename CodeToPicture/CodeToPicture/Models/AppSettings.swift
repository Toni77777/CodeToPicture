import SwiftUI

@Observable
@MainActor
final class AppSettings {
    @ObservationIgnored
    @AppStorage("selectedThemeID") var selectedThemeID: String = "dracula"

    @ObservationIgnored
    @AppStorage("fontSize") var fontSize: Double = 14

    @ObservationIgnored
    @AppStorage("padding") var padding: Double = 32

    @ObservationIgnored
    @AppStorage("cornerRadius") var cornerRadius: Double = 10

    @ObservationIgnored
    @AppStorage("showLineNumbers") var showLineNumbers: Bool = true

    @ObservationIgnored
    @AppStorage("showWindowFrame") var showWindowFrame: Bool = true

    @ObservationIgnored
    @AppStorage("backgroundHex") var backgroundColorHex: String = "#1e1e2e"

    @ObservationIgnored
    @AppStorage("fontFamily") var fontFamily: String = "SF Mono"

    @ObservationIgnored
    @AppStorage("exportScale") var exportScale: Double = 2.0

    @ObservationIgnored
    @AppStorage("menuBarEnabled") var menuBarModeEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("windowFrameStyle") var windowFrameStyle: String = "macos"
}
