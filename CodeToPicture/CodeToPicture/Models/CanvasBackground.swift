import Foundation

struct GradientStop: Codable, Sendable, Identifiable, Equatable {
    var id: UUID = UUID()
    var colorHex: String
    var position: Double
}

enum CanvasBackground: Codable, Sendable, Equatable {
    case none
    case solid(hex: String)
    case linearGradient(stops: [GradientStop], angle: Double)
    case radialGradient(stops: [GradientStop], centerX: Double, centerY: Double)
    case meshGradient(colors: [String], animated: Bool)
}

struct GradientPreset: Identifiable {
    var id: String
    var name: String
    var background: CanvasBackground
    var isFree: Bool
}
