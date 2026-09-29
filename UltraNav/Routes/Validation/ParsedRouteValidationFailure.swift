import Foundation

/// Specific failures detected when validating raw parsed GPX documents.
public enum ParsedRouteValidationFailure: Error, Equatable, Sendable {
    case emptyDocument
    case noUsableCoordinates
    case insufficientPoints(found: Int, minimumRequired: Int)
    case excessivePoints(found: Int, maximumAllowed: Int)
    case invalidCoordinate(latitude: Double, longitude: Double, reason: String)
    case unresolvableSegmentGaps
}
