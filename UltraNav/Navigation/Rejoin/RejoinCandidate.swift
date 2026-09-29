import Foundation

/// Confidence classification for a rejoin candidate evaluated against the route.
enum RejoinConfidence: Int, Comparable, Equatable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: RejoinConfidence, rhs: RejoinConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Strategy used when searching the route geometry for candidate rejoin locations.
enum RejoinSearchStrategy: Equatable, Sendable {
    case nearLastStableProgress
    case forwardBiasedSpatial
    case expandedSpatial
    case backwardRecovery
    case fullRouteFallback
}

/// Represents a candidate projection on the route geometry for rejoining after a deviation.
struct RejoinCandidate: Equatable, Sendable {
    let routeMatch: RouteMatch
    let progressDeltaFromLastStableMeters: Double
    let crossTrackScore: Double
    let continuityScore: Double
    let headingScore: Double?
    let forwardPreferenceScore: Double
    let ambiguityPenalty: Double
    let totalScore: Double
    let confidence: RejoinConfidence
    let searchStrategy: RejoinSearchStrategy

    init(
        routeMatch: RouteMatch,
        progressDeltaFromLastStableMeters: Double,
        crossTrackScore: Double,
        continuityScore: Double,
        headingScore: Double? = nil,
        forwardPreferenceScore: Double,
        ambiguityPenalty: Double = 0.0,
        totalScore: Double,
        confidence: RejoinConfidence,
        searchStrategy: RejoinSearchStrategy = .nearLastStableProgress
    ) {
        self.routeMatch = routeMatch
        self.progressDeltaFromLastStableMeters = progressDeltaFromLastStableMeters
        self.crossTrackScore = crossTrackScore
        self.continuityScore = continuityScore
        self.headingScore = headingScore
        self.forwardPreferenceScore = forwardPreferenceScore
        self.ambiguityPenalty = ambiguityPenalty
        self.totalScore = totalScore
        self.confidence = confidence
        self.searchStrategy = searchStrategy
    }
}
