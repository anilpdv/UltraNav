import Foundation

/// Weighting configuration for candidate scoring components.
struct RejoinScoringWeights: Equatable, Sendable {
    var proximity: Double
    var continuity: Double
    var forwardPreference: Double
    var heading: Double
    var persistence: Double

    static let standard = RejoinScoringWeights(
        proximity: 0.35,
        continuity: 0.25,
        forwardPreference: 0.15,
        heading: 0.15,
        persistence: 0.10
    )

    init(
        proximity: Double = 0.35,
        continuity: Double = 0.25,
        forwardPreference: Double = 0.15,
        heading: Double = 0.15,
        persistence: Double = 0.10
    ) {
        self.proximity = proximity
        self.continuity = continuity
        self.forwardPreference = forwardPreference
        self.heading = heading
        self.persistence = persistence
    }
}

/// Configuration parameters for candidate search, filtering, scoring, and confirmation.
struct RejoinConfiguration: Equatable, Sendable {
    var maximumCandidateCrossTrackMeters: Double
    var nearProgressForwardMeters: Double
    var nearProgressBackwardMeters: Double
    var candidatePersistenceDistanceMeters: Double
    var maximumHeadingDifferenceDegrees: Double
    var requiredConfirmations: Int
    var ambiguityScoreThreshold: Double
    var minimumSpeedForHeadingThresholdMetersPerSecond: Double
    var scoringWeights: RejoinScoringWeights

    static let standard = RejoinConfiguration()

    init(
        maximumCandidateCrossTrackMeters: Double = 100.0,
        nearProgressForwardMeters: Double = 500.0,
        nearProgressBackwardMeters: Double = 50.0,
        candidatePersistenceDistanceMeters: Double = 30.0,
        maximumHeadingDifferenceDegrees: Double = 90.0,
        requiredConfirmations: Int = 2,
        ambiguityScoreThreshold: Double = 0.15,
        minimumSpeedForHeadingThresholdMetersPerSecond: Double = 1.5,
        scoringWeights: RejoinScoringWeights = .standard
    ) {
        self.maximumCandidateCrossTrackMeters = maximumCandidateCrossTrackMeters
        self.nearProgressForwardMeters = nearProgressForwardMeters
        self.nearProgressBackwardMeters = nearProgressBackwardMeters
        self.candidatePersistenceDistanceMeters = candidatePersistenceDistanceMeters
        self.maximumHeadingDifferenceDegrees = maximumHeadingDifferenceDegrees
        self.requiredConfirmations = requiredConfirmations
        self.ambiguityScoreThreshold = ambiguityScoreThreshold
        self.minimumSpeedForHeadingThresholdMetersPerSecond = minimumSpeedForHeadingThresholdMetersPerSecond
        self.scoringWeights = scoringWeights
    }
}
