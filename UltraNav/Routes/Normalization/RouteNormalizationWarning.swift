import Foundation

/// Non-fatal warnings observed during route normalization.
public enum RouteNormalizationWarning: Equatable, Sendable {
    case duplicatePointsFiltered(count: Int)
    case missingElevationInterpolated(count: Int)
    case negativeElevationClamped(count: Int)
    case fallbackRoutePointsUsed
}
