import Foundation

struct DiagnosticExport: Equatable, Sendable {
    let fileName: String
    let data: Data
    let contentType: String

    init(fileName: String, data: Data, contentType: String = "application/json") {
        self.fileName = fileName
        self.data = data
        self.contentType = contentType
    }
}

protocol DiagnosticExporting: Sendable {
    func makeExport() async throws -> DiagnosticExport
}
