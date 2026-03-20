import Foundation

@Observable
@MainActor
final class EditorViewModel {
    var code: String = ""
    var language: String = "auto"
}
