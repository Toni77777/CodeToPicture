import Foundation

struct BatchExportItem: Identifiable, Sendable {
    var id: UUID = UUID()
    var fileURL: URL
    var filename: String
    var detectedLanguage: String
    var status: Status = .waiting

    enum Status: Sendable {
        case waiting, processing, done, failed(String)
    }
}
