import Foundation

struct Theme: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var isDark: Bool
    var backgroundColorHex: String
    var highlightJSName: String
    var isPro: Bool
}
