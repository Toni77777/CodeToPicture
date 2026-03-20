import SwiftUI

struct WindowFrameView: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: "#FF5F57")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#FEBC2E")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#28C840")).frame(width: 12, height: 12)
        }
    }
}

#Preview {
    WindowFrameView()
        .padding()
        .background(.black)
}
