import Foundation

/// Protocol for evaluating rejoin candidates against confirmation policies to produce a RejoinDecision.
protocol RejoinEvaluating: Sendable {
    func evaluate(
        candidates: [RejoinCandidate],
        previousCandidate: RejoinCandidate?,
        confirmationCount: Int,
        context: RejoinSearchContext,
        configuration: RejoinConfiguration
    ) -> RejoinDecision
}

/// Evaluates rejoin candidate telemetry and confirmation history.
struct RejoinEvaluator: RejoinEvaluating {
    init() {}

    func evaluate(
        candidates: [RejoinCandidate],
        previousCandidate: RejoinCandidate?,
        confirmationCount: Int,
        context: RejoinSearchContext,
        configuration: RejoinConfiguration
    ) -> RejoinDecision {
        guard let best = candidates.first else {
            return .unavailable(.noCandidatesWithinRadius)
        }

        // Check for ambiguous candidates
        if best.ambiguityPenalty > 0.0 {
            return .waitForEvidence(reason: .ambiguousCandidates)
        }

        // Check for low confidence candidates
        if best.confidence == .low {
            return .waitForEvidence(reason: .insufficientConfidence)
        }

        // Heading conflict verification
        if let headingDiff = best.routeMatch.headingDifferenceDegrees,
           headingDiff > configuration.maximumHeadingDifferenceDegrees {
            return .waitForEvidence(reason: .headingConflict)
        }

        // If candidate jumped a significant forward distance (> 1km), require confirmation persistence
        if abs(best.progressDeltaFromLastStableMeters) > 1000.0 && confirmationCount < configuration.requiredConfirmations {
            return .waitForEvidence(reason: .progressJumpNeedsConfirmation)
        }

        // Confirmation threshold check
        if confirmationCount >= configuration.requiredConfirmations {
            return .rejoined(best)
        }

        // Exceptional high-confidence single confirmation check for tight proximity and small progress delta
        if best.confidence == .high &&
           best.routeMatch.crossTrackDistanceMeters <= 10.0 &&
           abs(best.progressDeltaFromLastStableMeters) <= 50.0 &&
           confirmationCount >= 1 {
            return .rejoined(best)
        }

        return .candidateAvailable(best)
    }
}
