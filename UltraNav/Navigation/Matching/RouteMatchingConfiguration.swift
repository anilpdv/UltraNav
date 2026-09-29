import Foundation

/// Configuration parameters and scoring weights for RouteMatcher.
public struct RouteMatchingConfiguration: Equatable, Sendable {
    public let searchRadiusMeters: Double
    public let maxOffRouteDistanceMeters: Double
    public let crossTrackWeight: Double
    public let headingWeight: Double
    public let backwardProgressPenaltyPerMeter: Double
    public let forwardJumpPenaltyPerMeter: Double
    public let headingRelevanceSpeedThresholdMetersPerSecond: Double
    public let forwardCandidateWindow: Int
    public let backwardCandidateWindow: Int

    public init(
        searchRadiusMeters: Double = 120.0,
        maxOffRouteDistanceMeters: Double = 60.0,
        crossTrackWeight: Double = 1.0,
        headingWeight: Double = 0.3,
        backwardProgressPenaltyPerMeter: Double = 2.0,
        forwardJumpPenaltyPerMeter: Double = 0.5,
        headingRelevanceSpeedThresholdMetersPerSecond: Double = 1.5,
        forwardCandidateWindow: Int = 30,
        backwardCandidateWindow: Int = 10
    ) {
        self.searchRadiusMeters = searchRadiusMeters
        self.maxOffRouteDistanceMeters = maxOffRouteDistanceMeters
        self.crossTrackWeight = crossTrackWeight
        self.headingWeight = headingWeight
        self.backwardProgressPenaltyPerMeter = backwardProgressPenaltyPerMeter
        self.forwardJumpPenaltyPerMeter = forwardJumpPenaltyPerMeter
        self.headingRelevanceSpeedThresholdMetersPerSecond = headingRelevanceSpeedThresholdMetersPerSecond
        self.forwardCandidateWindow = forwardCandidateWindow
        self.backwardCandidateWindow = backwardCandidateWindow
    }

    public static let standard = RouteMatchingConfiguration()
}
