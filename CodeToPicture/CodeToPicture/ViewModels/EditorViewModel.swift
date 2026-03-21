import SwiftUI

@Observable
@MainActor
final class EditorViewModel {
    var code: String = "// Paste or type your code here\nfunc greet(_ name: String) -> String {\n    return \"Hello, \\(name)!\"\n}\n\nprint(greet(\"World\"))"
    var language: String = "auto"

    func setLanguage(_ lang: String) {
        language = lang
    }
}
