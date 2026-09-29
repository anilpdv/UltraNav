import Foundation

/// Progress reconciliation outcome classification.
enum RejoinProgressOutcome: Equatable, Sendable {
    case sameSection
    case advancedForward
    case movedBackward
    case largeForwardSkip
    case largeBackwardRejoin
}

/// Policy configuration for how route progress reconciles after rejoining.
struct RejoinProgressPolicy: Equatable, Sendable {
    var allowForwardSkip: Bool
    var allowBackwardRejoin: Bool
    var preserveMaximumReachedDistance: Bool
    var completionRequiresPostRejoinEvidence: Bool

    static let standard = RejoinProgressPolicy(
        allowForwardSkip: true,
        allowBackwardRejoin: true,
        preserveMaximumReachedDistance: true,
        completionRequiresPostRejoinEvidence: true
    )

    init(
        allowForwardSkip: Bool = true,
        allowBackwardRejoin: Bool = true,
        preserveMaximumReachedDistance: Bool = true,
        completionRequiresPostRejoinEvidence: Bool = true
    ) {
        self.allowForwardSkip = allowForwardSkip
        self.allowBackwardRejoin = allowBackwardRejoin
        self.preserveMaximumReachedDistance = preserveMaximumReachedDistance
        self.completionRequiresPostRejoinEvidence = completionRequiresPostRejoinEvidence
    }
}

/// Structured result of reconciling navigation route progress after a rejoin event.
struct RejoinProgressReconciliation: Equatable, Sendable {
    let previousDistanceMeters: Double?
    let rejoinedDistanceMeters: Double
    let skippedForwardDistanceMeters: Double
    let movedBackwardDistanceMeters: Double
    let outcome: RejoinProgressOutcome
    let newMaximumReachedDistanceMeters: Double

    init(
        previousDistanceMeters: Double?,
        rejoinedDistanceMeters: Double,
        skippedForwardDistanceMeters: Double,
        movedBackwardDistanceMeters: Double,
        outcome: RejoinProgressOutcome,
        newMaximumReachedDistanceMeters: Double
    ) {
        self.previousDistanceMeters = previousDistanceMeters
        self.rejoinedDistanceMeters = rejoinedDistanceMeters
        self.skippedForwardDistanceMeters = skippedForwardDistanceMeters
        self.movedBackwardDistanceMeters = movedBackwardDistanceMeters
        self.outcome = outcome
        self.newMaximumReachedDistanceMeters = newMaximumReachedDistanceMeters
    }
}

/// Protocol for reconciling distance and trajectory upon rejoining.
protocol RejoinProgressReconciling: Sendable {
    func reconcile(
        previousDistanceMeters: Double?,
        maximumReachedDistanceMeters: Double,
        candidate: RejoinCandidate,
        routeTotalDistanceMeters: Double,
        policy: RejoinProgressPolicy
    ) -> RejoinProgressReconciliation
}

/// Standard implementation of RejoinProgressReconciling.
struct RejoinProgressReconciler: RejoinProgressReconciling {
    init() {}

    func reconcile(
        previousDistanceMeters: Double?,
        maximumReachedDistanceMeters: Double,
        candidate: RejoinCandidate,
        routeTotalDistanceMeters: Double,
        policy: RejoinProgressPolicy = .standard
    ) -> RejoinProgressReconciliation {
        let prevDist = previousDistanceMeters ?? 0.0
        let newDist = candidate.routeMatch.distanceAlongRouteMeters
        let delta = newDist - prevDist

        let outcome: RejoinProgressOutcome
        let skippedForward: Double
        let movedBackward: Double

        if abs(delta) <= 25.0 {
            outcome = .sameSection
            skippedForward = max(0.0, delta)
            movedBackward = max(0.0, -delta)
        } else if delta > 500.0 {
            outcome = .largeForwardSkip
            skippedForward = delta
            movedBackward = 0.0
        } else if delta > 0.0 {
            outcome = .advancedForward
            skippedForward = delta
            movedBackward = 0.0
        } else if delta < -500.0 {
            outcome = .largeBackwardRejoin
            skippedForward = 0.0
            movedBackward = -delta
        } else {
            outcome = .movedBackward
            skippedForward = 0.0
            movedBackward = -delta
        }

        let newMax = policy.preserveMaximumReachedDistance ? max(maximumReachedDistanceMeters, newDist) : newDist

        return RejoinProgressReconciliation(
            previousDistanceMeters: previousDistanceMeters,
            rejoinedDistanceMeters: newDist,
            skippedForwardDistanceMeters: skippedForward,
            movedBackwardDistanceMeters: movedBackward,
            outcome: outcome,
            newMaximumReachedDistanceMeters: newMax
        )
    }
}
