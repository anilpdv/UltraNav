import Foundation

/// Policy defining constraints for parsed GPX document validation.
public struct ParsedRouteValidationPolicy: Equatable, Sendable {
    public let minimumPointCount: Int
    public let maximumPointCount: Int
    public let allowRoutePointsAsFallback: Bool
    public let maximumDistanceGapMeters: Double?

    public init(
        minimumPointCount: Int = 2,
        maximumPointCount: Int = 500_000,
        allowRoutePointsAsFallback: Bool = true,
        maximumDistanceGapMeters: Double? = nil
    ) {
        self.minimumPointCount = minimumPointCount
        self.maximumPointCount = maximumPointCount
        self.allowRoutePointsAsFallback = allowRoutePointsAsFallback
        self.maximumDistanceGapMeters = maximumDistanceGapMeters
    }

    public static let `default` = ParsedRouteValidationPolicy()
}
