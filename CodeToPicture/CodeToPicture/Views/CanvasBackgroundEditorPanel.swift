import SwiftUI

struct CanvasBackgroundEditorPanel: View {
    @Bindable var bgVM: CanvasBackgroundViewModel
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Section("Canvas Background") {
            modePicker

            switch bgVM.mode {
            case .none:
                EmptyView()
            case .solid:
                solidEditor
            case .linear:
                linearEditor
            case .radial:
                radialEditor
            case .mesh:
                meshEditor
            }

            presetsRow
        }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        Picker("", selection: $bgVM.mode) {
            Text("None").tag(BackgroundMode.none)
            Text("Solid").tag(BackgroundMode.solid)
            Text("Linear").tag(BackgroundMode.linear)
            Text("Radial").tag(BackgroundMode.radial)
            Text("Mesh").tag(BackgroundMode.mesh)
        }
        .pickerStyle(.segmented)
        .onChange(of: bgVM.mode) {
            bgVM.apply(to: settings)
        }
    }

    // MARK: - Solid

    private var solidEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            ColorPicker("Color", selection: solidColorBinding)
                .onChange(of: bgVM.solidHex) { bgVM.apply(to: settings) }

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 8), spacing: 6) {
                ForEach(CanvasBackgroundViewModel.solidPresets, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        }
                        .overlay {
                            if bgVM.solidHex == hex {
                                Circle().stroke(Color.accentColor, lineWidth: 2)
                            }
                        }
                        .onTapGesture {
                            bgVM.solidHex = hex
                            bgVM.apply(to: settings)
                        }
                }
            }
        }
    }

    // MARK: - Linear

    private var linearEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            GradientStopsEditor(stops: $bgVM.linearStops)
                .onChange(of: bgVM.linearStops) { bgVM.apply(to: settings) }

            LabeledContent("Angle  \(Int(bgVM.linearAngle))\u{00B0}") {
                Slider(value: $bgVM.linearAngle, in: 0...360, step: 15)
            }
            .onChange(of: bgVM.linearAngle) { bgVM.apply(to: settings) }

            // Mini preview
            LinearGradient(
                stops: bgVM.linearStops.map { Gradient.Stop(color: Color(hex: $0.colorHex), location: $0.position) },
                startPoint: UnitPoint(angle: bgVM.linearAngle),
                endPoint: UnitPoint(angle: bgVM.linearAngle + 180)
            )
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Radial

    private var radialEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            GradientStopsEditor(stops: $bgVM.radialStops)
                .onChange(of: bgVM.radialStops) { bgVM.apply(to: settings) }

            LabeledContent("Center X  \(Int(bgVM.radialCenterX * 100))%") {
                Slider(value: $bgVM.radialCenterX, in: 0...1)
            }
            .onChange(of: bgVM.radialCenterX) { bgVM.apply(to: settings) }

            LabeledContent("Center Y  \(Int(bgVM.radialCenterY * 100))%") {
                Slider(value: $bgVM.radialCenterY, in: 0...1)
            }
            .onChange(of: bgVM.radialCenterY) { bgVM.apply(to: settings) }
        }
    }

    // MARK: - Mesh

    private var meshEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                ForEach(0..<9, id: \.self) { i in
                    ColorPicker("", selection: meshColorBinding(at: i))
                        .labelsHidden()
                        .frame(width: 36, height: 36)
                }
            }
            .onChange(of: bgVM.meshColors) { bgVM.apply(to: settings) }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(CanvasBackgroundViewModel.meshPresets.enumerated()), id: \.offset) { _, palette in
                        meshPalettePreview(colors: palette)
                            .frame(width: 60, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onTapGesture {
                                bgVM.meshColors = palette
                                bgVM.apply(to: settings)
                            }
                    }
                }
            }

            Toggle("Animate (slow drift)", isOn: $bgVM.meshAnimated)
                .onChange(of: bgVM.meshAnimated) { bgVM.apply(to: settings) }
        }
    }

    // MARK: - Gradient presets

    private var presetsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Presets")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CanvasBackgroundViewModel.gradientPresets) { preset in
                        VStack(spacing: 2) {
                            presetPreview(preset.background)
                                .frame(width: 60, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(preset.name)
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            bgVM.applyPreset(preset)
                            bgVM.apply(to: settings)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var solidColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: bgVM.solidHex) },
            set: { bgVM.solidHex = $0.toHex() }
        )
    }

    private func meshColorBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: { Color(hex: bgVM.meshColors[index]) },
            set: { bgVM.meshColors[index] = $0.toHex() }
        )
    }

    @ViewBuilder
    private func presetPreview(_ bg: CanvasBackground) -> some View {
        switch bg {
        case .none:
            Color.clear
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
                endRadius: 40
            )
        case .meshGradient(let colors, _):
            let pts: [SIMD2<Float>] = [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ]
            MeshGradient(width: 3, height: 3, points: pts, colors: colors.map { Color(hex: $0) })
        }
    }

    @ViewBuilder
    private func meshPalettePreview(colors: [String]) -> some View {
        let pts: [SIMD2<Float>] = [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.5, 0.5], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1]
        ]
        MeshGradient(width: 3, height: 3, points: pts, colors: colors.map { Color(hex: $0) })
    }
}
