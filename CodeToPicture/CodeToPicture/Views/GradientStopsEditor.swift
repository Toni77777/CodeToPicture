import SwiftUI

struct GradientStopsEditor: View {
    @Binding var stops: [GradientStop]

    var body: some View {
        VStack(spacing: 8) {
            // Preview bar with handles
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        stops: stops.map { Gradient.Stop(color: Color(hex: $0.colorHex), location: $0.position) },
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    ForEach($stops) { $stop in
                        Circle()
                            .fill(Color(hex: stop.colorHex))
                            .frame(width: 18, height: 18)
                            .overlay { Circle().stroke(Color.white, lineWidth: 2) }
                            .shadow(radius: 2)
                            .position(x: stop.position * geo.size.width, y: 12)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let clamped = min(max(value.location.x / geo.size.width, 0), 1)
                                        stop.position = clamped
                                    }
                            )
                    }
                }
            }
            .frame(height: 24)

            // Per-stop controls
            ForEach($stops) { $stop in
                HStack(spacing: 6) {
                    ColorPicker("", selection: colorBinding(for: $stop))
                        .labelsHidden()
                        .frame(width: 28)
                    Slider(value: $stop.position, in: 0...1)
                    Text("\(Int(stop.position * 100))%")
                        .font(.caption)
                        .frame(width: 32, alignment: .trailing)
                    if stops.count > 2 {
                        Button {
                            stops.removeAll { $0.id == stop.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }
            }

            if stops.count < 5 {
                Button("+ Add Stop") {
                    stops.append(GradientStop(colorHex: "#ffffff", position: 0.5))
                    stops.sort { $0.position < $1.position }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .font(.caption)
            }
        }
    }

    private func colorBinding(for stop: Binding<GradientStop>) -> Binding<Color> {
        Binding(
            get: { Color(hex: stop.wrappedValue.colorHex) },
            set: { stop.wrappedValue.colorHex = $0.toHex() }
        )
    }
}
