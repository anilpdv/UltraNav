import Foundation

/// Protocol isolating raw GPX XML parsing into parsed document value types and reports.
public protocol GPXParsing: Sendable {
    func parse(data: Data) async throws -> GPXParsedDocument
    func parseReport(data: Data, sourceMetadata: GPXSourceMetadata?) async throws -> GPXParsingReport
}

public extension GPXParsing {
    func parse(data: Data) async throws -> GPXParsedDocument {
        try await parseReport(data: data, sourceMetadata: nil).document
    }
}
