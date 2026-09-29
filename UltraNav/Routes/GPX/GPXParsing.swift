import Foundation

/// Protocol isolating raw GPX XML parsing into parsed document value types.
public protocol GPXParsing: Sendable {
    func parse(data: Data) async throws -> GPXParsedDocument
}
