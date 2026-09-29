import Foundation

/// Non-fatal warnings observed during route normalization.
public enum RouteNormalizationWarning: Equatable, Sendable {
    case duplicatePointsFiltered(count: Int)
    case missingElevationDetected(count: Int)
    case negativeElevationClamped(count: Int)
    case multipleTracksMerged(count: Int)
    case disconnectedSegmentsDetected(gapMeters: Double)
    case largePointGapDetected(distanceMeters: Double)
    case antimeridianCrossingDetected
    case contentSelectionWarning(String)
}
