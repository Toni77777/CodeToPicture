import Foundation

struct SocialPreset: Identifiable, Codable, Sendable {
    var id: String
    var name: String
    var symbolName: String
    var aspectRatio: Double?
    var padding: Double
    var isBuiltIn: Bool
}
