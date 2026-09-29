import Foundation

/// Failures during the transformation of a parsed document into a canonical Route.
public enum RouteNormalizationFailure: Error, Equatable, Sendable {
    case noPointsRemainingAfterFiltering
    case nonFiniteDistanceDelta(segmentIndex: Int, pointIndex: Int)
    case brokenSegmentIndices
    case identityGenerationFailed(String)
    case dataQualityRejected(discardRatio: Double, limit: Double)
    case canonicalValidationFailed(String)
}
