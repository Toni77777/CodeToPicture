import SwiftUI

struct CodeEditorView: View {
    @Environment(EditorViewModel.self) private var vm
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        @Bindable var vm = vm
        HighlightedCodeEditor(
            code: $vm.code,
            language: vm.language,
            theme: themeManager.selectedTheme,
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily
        )
    }
}
