import Foundation

/// Policy configuring how raw GPX documents are transformed into canonical Route models.
public struct RouteNormalizationPolicy: Equatable, Sendable {
    public let minimumPointSpacingMeters: Double
    public let preserveTrackSegments: Bool
    public let clampNegativeElevationToZero: Bool
    public let elevationNoiseThresholdMeters: Double

    public init(
        minimumPointSpacingMeters: Double = 0.5,
        preserveTrackSegments: Bool = true,
        clampNegativeElevationToZero: Bool = false,
        elevationNoiseThresholdMeters: Double = 0.4
    ) {
        self.minimumPointSpacingMeters = minimumPointSpacingMeters
        self.preserveTrackSegments = preserveTrackSegments
        self.clampNegativeElevationToZero = clampNegativeElevationToZero
        self.elevationNoiseThresholdMeters = elevationNoiseThresholdMeters
    }

    public static let `default` = RouteNormalizationPolicy()
}
