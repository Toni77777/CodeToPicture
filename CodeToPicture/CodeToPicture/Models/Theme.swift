import Foundation

struct Theme: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let backgroundColor: String
    let foregroundColor: String
    let accentColor: String
    let lineNumberColor: String
    let selectionColor: String
    let keywords: String
    let strings: String
    let comments: String
    let functions: String
    let types: String
    let numbers: String
}
