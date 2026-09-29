import Foundation

/// Strongly typed failures that can occur during raw GPX XML streaming parsing.
public enum GPXParserFailure: Error, Equatable, Sendable {
    case emptyDocument
    case invalidEncoding
    case fileTooLarge(bytes: Int, limit: Int)
    case malformedXML(message: String)
    case xmlParserError(code: Int, description: String)
    case unsupportedRootElement(String)
    case elementDepthExceeded(depth: Int, limit: Int)
    case textLengthExceeded(element: String, length: Int, limit: Int)
    case pointLimitExceeded(limit: Int)
    case waypointLimitExceeded(limit: Int)
    case trackLimitExceeded(limit: Int)
    case segmentLimitExceeded(limit: Int)
    case invalidRequiredCoordinate
    case noSupportedContent
    case unreadableSource
    case cancelled
    case unexpected(String)
}
