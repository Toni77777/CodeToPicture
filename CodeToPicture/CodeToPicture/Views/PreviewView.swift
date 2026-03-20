import SwiftUI

struct PreviewView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Text("Preview")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PreviewView()
        .environment(AppSettings())
}
