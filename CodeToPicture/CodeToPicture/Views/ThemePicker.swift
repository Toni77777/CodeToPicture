import SwiftUI

struct ThemePicker: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorViewModel.self) private var editorVM

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(themeManager.themes) { theme in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: theme.backgroundColorHex))
                            .frame(width: 48, height: 36)
                            .overlay {
                                if theme.isPro {
                                    Text("\u{2605}")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .overlay {
                                if themeManager.selectedTheme.id == theme.id {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor, lineWidth: 2)
                                }
                            }

                        Text(theme.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        themeManager.applyTheme(theme, editorVM: editorVM)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Color hex helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB)
            ?? NSColor(self).usingColorSpace(.deviceRGB)
            ?? NSColor(self)
        let r = Int((nsColor.redComponent * 255).rounded())
        let g = Int((nsColor.greenComponent * 255).rounded())
        let b = Int((nsColor.blueComponent * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}

#Preview {
    ThemePicker()
        .environment(ThemeManager())
        .environment(EditorViewModel())
        .frame(width: 280)
}
