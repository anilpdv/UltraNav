import Foundation

/// Strongly typed failures that can occur during raw GPX XML parsing.
public enum GPXParserFailure: Error, Equatable, Sendable {
    case invalidEncoding
    case emptyDocument
    case malformedXML(message: String)
    case xmlParserError(code: Int, description: String)
    case unreadableSource
}
