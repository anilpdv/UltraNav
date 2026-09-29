import Foundation

/// Policy configuring how raw GPX documents are transformed into canonical Route models.
public struct RouteNormalizationPolicy: Equatable, Sendable {
    public let version: RouteNormalizationVersion
    public let duplicatePointPolicy: DuplicatePointPolicy
    public let contentSelectionPolicy: GPXContentSelectionPolicy
    public let minimumPointSpacingMeters: Double
    public let maximumGapDistanceMeters: Double
    public let preserveTrackSegments: Bool
    public let clampNegativeElevationToZero: Bool
    public let elevationNoiseThresholdMeters: Double

    public init(
        version: RouteNormalizationVersion = .version2,
        duplicatePointPolicy: DuplicatePointPolicy = .removeExactConsecutiveSamples,
        contentSelectionPolicy: GPXContentSelectionPolicy = .preferTracks,
        minimumPointSpacingMeters: Double = 0.5,
        maximumGapDistanceMeters: Double = 50_000.0,
        preserveTrackSegments: Bool = true,
        clampNegativeElevationToZero: Bool = false,
        elevationNoiseThresholdMeters: Double = 0.4
    ) {
        self.version = version
        self.duplicatePointPolicy = duplicatePointPolicy
        self.contentSelectionPolicy = contentSelectionPolicy
        self.minimumPointSpacingMeters = minimumPointSpacingMeters
        self.maximumGapDistanceMeters = maximumGapDistanceMeters
        self.preserveTrackSegments = preserveTrackSegments
        self.clampNegativeElevationToZero = clampNegativeElevationToZero
        self.elevationNoiseThresholdMeters = elevationNoiseThresholdMeters
    }

    public static let `default` = RouteNormalizationPolicy()
}
