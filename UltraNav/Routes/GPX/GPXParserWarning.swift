import Foundation

/// Non-fatal diagnostic warning produced during GPX parsing.
public enum GPXParserWarning: Equatable, Sendable {
    case unsupportedVersionAccepted(String)
    case missingVersionAccepted
    case invalidElevationDiscarded(count: Int)
    case invalidTimestampDiscarded(count: Int)
    case invalidPointDiscarded(count: Int)
    case unknownElementIgnored(name: String, count: Int)
    case unknownExtensionIgnored(namespace: String?)
    case emptySegmentIgnored(count: Int)
    case emptyTrackIgnored(count: Int)
    case textTruncated(element: String)
}
