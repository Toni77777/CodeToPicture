import SwiftUI

enum BackgroundMode: String, CaseIterable, Sendable {
    case none, solid, linear, radial, mesh
}

@Observable
@MainActor
final class CanvasBackgroundViewModel {
    var mode: BackgroundMode = .solid
    var solidHex: String = "#18181b"

    // Linear
    var linearStops: [GradientStop] = [
        GradientStop(colorHex: "#7f5af0", position: 0),
        GradientStop(colorHex: "#2cb67d", position: 1)
    ]
    var linearAngle: Double = 135

    // Radial
    var radialStops: [GradientStop] = [
        GradientStop(colorHex: "#ff6b6b", position: 0),
        GradientStop(colorHex: "#1a1a2e", position: 1)
    ]
    var radialCenterX: Double = 0.5
    var radialCenterY: Double = 0.5

    // Mesh
    var meshColors: [String] = [
        "#7f5af0", "#2cb67d", "#ff6b6b",
        "#ffd166", "#06d6a0", "#118ab2",
        "#ef476f", "#073b4c", "#264653"
    ]
    var meshAnimated: Bool = false

    var currentBackground: CanvasBackground {
        switch mode {
        case .solid:  return .solid(hex: solidHex)
        case .linear: return .linearGradient(stops: linearStops, angle: linearAngle)
        case .radial: return .radialGradient(stops: radialStops, centerX: radialCenterX, centerY: radialCenterY)
        case .mesh:   return .meshGradient(colors: meshColors, animated: meshAnimated)
        case .none:   return .none
        }
    }

    func apply(to settings: AppSettings) {
        settings.canvasBackground = currentBackground
        settings.saveCanvasBackground()
    }

    func loadFrom(_ settings: AppSettings) {
        switch settings.canvasBackground {
        case .none:
            mode = .none
        case .solid(let hex):
            mode = .solid
            solidHex = hex
        case .linearGradient(let stops, let angle):
            mode = .linear
            linearStops = stops
            linearAngle = angle
        case .radialGradient(let stops, let cx, let cy):
            mode = .radial
            radialStops = stops
            radialCenterX = cx
            radialCenterY = cy
        case .meshGradient(let colors, let animated):
            mode = .mesh
            meshColors = colors
            meshAnimated = animated
        }
    }

    func applyPreset(_ preset: GradientPreset) {
        switch preset.background {
        case .none:
            mode = .none
        case .solid(let hex):
            mode = .solid
            solidHex = hex
        case .linearGradient(let stops, let angle):
            mode = .linear
            linearStops = stops
            linearAngle = angle
        case .radialGradient(let stops, let cx, let cy):
            mode = .radial
            radialStops = stops
            radialCenterX = cx
            radialCenterY = cy
        case .meshGradient(let colors, let animated):
            mode = .mesh
            meshColors = colors
            meshAnimated = animated
        }
    }

    // MARK: - Presets

    static let gradientPresets: [GradientPreset] = [
        GradientPreset(
            id: "violet", name: "Violet",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#7f5af0", position: 0), GradientStop(colorHex: "#2cb67d", position: 1)],
                angle: 135),
            isFree: true),
        GradientPreset(
            id: "matrix", name: "Matrix",
            background: .solid(hex: "#0d0d0d"),
            isFree: true),
        GradientPreset(
            id: "aurora", name: "Aurora",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#00d2ff", position: 0), GradientStop(colorHex: "#3a7bd5", position: 1)],
                angle: 135),
            isFree: true),
        GradientPreset(
            id: "sunset", name: "Sunset",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#f7971e", position: 0), GradientStop(colorHex: "#ffd200", position: 0.5), GradientStop(colorHex: "#f7971e", position: 1)],
                angle: 180),
            isFree: true),
        GradientPreset(
            id: "candy", name: "Candy",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#f953c6", position: 0), GradientStop(colorHex: "#b91d73", position: 1)],
                angle: 135),
            isFree: true),
        GradientPreset(
            id: "ocean", name: "Ocean",
            background: .radialGradient(
                stops: [GradientStop(colorHex: "#1a1a2e", position: 0), GradientStop(colorHex: "#16213e", position: 0.5), GradientStop(colorHex: "#0f3460", position: 1)],
                centerX: 0.3, centerY: 0.3),
            isFree: true),
        GradientPreset(
            id: "forest", name: "Forest",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#134e5e", position: 0), GradientStop(colorHex: "#71b280", position: 1)],
                angle: 160),
            isFree: true),
        GradientPreset(
            id: "rose", name: "Rose",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#f43f5e", position: 0), GradientStop(colorHex: "#ec4899", position: 0.5), GradientStop(colorHex: "#8b5cf6", position: 1)],
                angle: 120),
            isFree: true),
        GradientPreset(
            id: "midnight", name: "Midnight",
            background: .radialGradient(
                stops: [GradientStop(colorHex: "#0f0c29", position: 0), GradientStop(colorHex: "#302b63", position: 0.5), GradientStop(colorHex: "#24243e", position: 1)],
                centerX: 0.5, centerY: 0.3),
            isFree: true),
        GradientPreset(
            id: "peach", name: "Peach",
            background: .linearGradient(
                stops: [GradientStop(colorHex: "#ffecd2", position: 0), GradientStop(colorHex: "#fcb69f", position: 1)],
                angle: 90),
            isFree: true),
    ]

    static let meshPresets: [[String]] = [
        ["#7f5af0", "#2cb67d", "#ff6b6b", "#ffd166", "#06d6a0", "#118ab2", "#ef476f", "#073b4c", "#264653"],
        ["#0f0c29", "#302b63", "#24243e", "#1a1a2e", "#16213e", "#0f3460", "#533483", "#2b2d42", "#8d99ae"],
        ["#f72585", "#b5179e", "#7209b7", "#560bad", "#480ca8", "#3a0ca3", "#3f37c9", "#4361ee", "#4cc9f0"],
        ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51", "#606c38", "#283618", "#dda15e", "#bc6c25"],
    ]

    static let solidPresets: [String] = [
        "#18181b", "#0f0f0f", "#1a1a2e", "#0d0d0d", "#1e1b4b",
        "#ffffff", "#f8fafc", "#f0fdf4", "#fefce8", "#fff1f2",
        "#7f5af0", "#2cb67d"
    ]
}
