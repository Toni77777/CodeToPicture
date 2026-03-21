import SwiftUI

struct CanvasBackgroundView: View {
    let background: CanvasBackground

    var body: some View {
        GeometryReader { geo in
            backgroundContent(for: background, size: geo.size)
        }
    }

    @ViewBuilder
    private func backgroundContent(for bg: CanvasBackground, size: CGSize) -> some View {
        switch bg {
        case .none:
            CheckerboardView()

        case .solid(let hex):
            Color(hex: hex)

        case .linearGradient(let stops, let angle):
            LinearGradient(
                stops: stops.map { Gradient.Stop(color: Color(hex: $0.colorHex), location: $0.position) },
                startPoint: UnitPoint(angle: angle),
                endPoint: UnitPoint(angle: angle + 180)
            )

        case .radialGradient(let stops, let cx, let cy):
            RadialGradient(
                stops: stops.map { Gradient.Stop(color: Color(hex: $0.colorHex), location: $0.position) },
                center: UnitPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.7
            )

        case .meshGradient(let colors, let animated):
            let points: [SIMD2<Float>] = [
                [0, 0],     [0.5, 0],   [1, 0],
                [0, 0.5],   [0.5, 0.5], [1, 0.5],
                [0, 1],     [0.5, 1],   [1, 1]
            ]
            let swiftColors = colors.map { Color(hex: $0) }
            if animated {
                AnimatedMeshView(baseColors: swiftColors, basePoints: points)
            } else {
                MeshGradient(width: 3, height: 3, points: points, colors: swiftColors)
            }
        }
    }
}

// MARK: - Checkerboard

struct CheckerboardView: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 12
            let cols = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            let light = Color(white: 0.85)
            let dark = Color(white: 0.65)

            for row in 0..<rows {
                for col in 0..<cols {
                    let color = (row + col).isMultiple(of: 2) ? light : dark
                    let rect = CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile, height: tile)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Animated Mesh

struct AnimatedMeshView: View {
    let baseColors: [Color]
    let basePoints: [SIMD2<Float>]
    @State private var phase: Float = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = Float(timeline.date.timeIntervalSinceReferenceDate)
            let animated = animatedPoints(time: t)
            MeshGradient(width: 3, height: 3, points: animated, colors: baseColors)
        }
        .onAppear { phase = Float.random(in: 0...(.pi * 2)) }
    }

    private func animatedPoints(time: Float) -> [SIMD2<Float>] {
        let speed: Float = 0.3
        var pts = basePoints
        // Drift the 4 corner points; keep edges clamped and center static
        let drift: Float = 0.06
        // top-left
        pts[0] = [drift * sin(time * speed + phase), drift * cos(time * speed + phase + 1)]
        // top-right
        pts[2] = [1 + drift * sin(time * speed + phase + 2), drift * cos(time * speed + phase + 3)]
        // bottom-left
        pts[6] = [drift * sin(time * speed + phase + 4), 1 + drift * cos(time * speed + phase + 5)]
        // bottom-right
        pts[8] = [1 + drift * sin(time * speed + phase + 6), 1 + drift * cos(time * speed + phase + 7)]
        // mid-edge points get subtle drift too
        pts[1] = [0.5 + drift * 0.5 * sin(time * speed + phase + 8), drift * 0.5 * cos(time * speed + phase + 9)]
        pts[3] = [drift * 0.5 * sin(time * speed + phase + 10), 0.5 + drift * 0.5 * cos(time * speed + phase + 11)]
        pts[5] = [1 + drift * 0.5 * sin(time * speed + phase + 12), 0.5 + drift * 0.5 * cos(time * speed + phase + 13)]
        pts[7] = [0.5 + drift * 0.5 * sin(time * speed + phase + 14), 1 + drift * 0.5 * cos(time * speed + phase + 15)]
        // center stays static
        pts[4] = [0.5, 0.5]
        return pts
    }
}

// MARK: - UnitPoint angle extension

extension UnitPoint {
    init(angle degrees: Double) {
        let radians = degrees * .pi / 180
        let x = 0.5 + 0.5 * cos(radians)
        let y = 0.5 + 0.5 * sin(radians)
        self.init(x: x, y: y)
    }
}
