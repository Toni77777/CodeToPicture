import SwiftUI

struct WindowFrameView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        switch settings.windowFrameStyle {
        case "chrome":
            chromeFrame
        case "arc":
            arcFrame
        case "none":
            EmptyView()
        default:
            macosFrame
        }
    }

    // MARK: - macOS traffic lights

    private var macosFrame: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: "#FF5F57")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#FEBC2E")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#28C840")).frame(width: 12, height: 12)
        }
    }

    // MARK: - Chrome-style tabs

    private var chromeFrame: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.1))
                .frame(width: 120, height: 28)
                .overlay(alignment: .leading) {
                    HStack(spacing: 6) {
                        Circle().fill(.white.opacity(0.3)).frame(width: 10, height: 10)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(width: 60, height: 10)
                    }
                    .padding(.leading, 10)
                }
            Spacer()
        }
    }

    // MARK: - Arc-style minimal

    private var arcFrame: some View {
        HStack(spacing: 6) {
            Circle().fill(.white.opacity(0.25)).frame(width: 10, height: 10)
            Circle().fill(.white.opacity(0.25)).frame(width: 10, height: 10)
            Circle().fill(.white.opacity(0.25)).frame(width: 10, height: 10)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.1))
                .frame(width: 100, height: 20)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WindowFrameView()
            .padding()
            .background(.black)
    }
    .environment(AppSettings())
}
