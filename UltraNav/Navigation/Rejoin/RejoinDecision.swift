import Foundation

/// Specific reason why candidate selection must wait for further evidence.
enum RejoinWaitReason: Equatable, Sendable {
    case insufficientConfidence
    case ambiguousCandidates
    case poorGPSQuality
    case candidateNotPersistent
    case progressJumpNeedsConfirmation
    case headingConflict
}

/// Reason why rejoin candidate search cannot produce a valid candidate.
enum RejoinUnavailableReason: Equatable, Sendable {
    case noCandidatesWithinRadius
    case routeMismatch
    case inactiveEpisode
}

/// The decision produced by evaluating candidates against rejoin confirmation criteria.
enum RejoinDecision: Equatable, Sendable {
    case waitForEvidence(reason: RejoinWaitReason)
    case candidateAvailable(RejoinCandidate)
    case rejoined(RejoinCandidate)
    case unavailable(RejoinUnavailableReason)
}
