import Foundation

/// Failures during the transformation of a parsed document into a canonical Route.
public enum RouteNormalizationFailure: Error, Equatable, Sendable {
    case noPointsRemainingAfterFiltering
    case distanceCalculationFailed
}
