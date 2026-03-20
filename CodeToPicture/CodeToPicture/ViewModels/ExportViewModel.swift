import Foundation

@Observable
@MainActor
final class ExportViewModel {
    var isExporting: Bool = false
    var lastExportURL: URL?
}
