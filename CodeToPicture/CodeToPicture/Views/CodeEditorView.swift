import SwiftUI

struct CodeEditorView: View {
    @Environment(EditorViewModel.self) private var vm
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var vm = vm
        TextEditor(text: $vm.code)
            .font(.system(size: settings.fontSize, design: .monospaced))
            .scrollContentBackground(.hidden)
            .foregroundStyle(.white)
            .padding(4)
            .background(Color(nsColor: NSColor(red: 0.16, green: 0.16, blue: 0.21, alpha: 1)))
    }
}
