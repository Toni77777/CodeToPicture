import SwiftUI

struct EditorView: View {
    @Environment(EditorViewModel.self) private var vm

    private let languages = [
        "auto",
        "swift", "python", "javascript", "typescript", "java",
        "c", "cpp", "csharp", "go", "rust",
        "ruby", "php", "kotlin", "scala", "sql",
        "html", "css", "shell", "json", "yaml"
    ]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            CodeEditorView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var toolbar: some View {
        HStack {
            Menu {
                ForEach(languages, id: \.self) { lang in
                    Button(lang == "auto" ? "Auto-detect" : lang) {
                        vm.setLanguage(lang)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text(vm.language == "auto" ? "Auto" : vm.language)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    EditorView()
        .environment(EditorViewModel())
        .environment(AppSettings())
        .environment(ThemeManager())
}
