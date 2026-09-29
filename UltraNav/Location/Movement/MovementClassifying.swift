import Foundation

/// Result of movement evidence evaluation.
public struct MovementClassificationResult: Equatable, Sendable {
    public let state: MovementState
    public let consecutiveMovingEvidence: Int
    public let consecutiveStationaryEvidence: Int

    public init(
        state: MovementState,
        consecutiveMovingEvidence: Int,
        consecutiveStationaryEvidence: Int
    ) {
        self.state = state
        self.consecutiveMovingEvidence = consecutiveMovingEvidence
        self.consecutiveStationaryEvidence = consecutiveStationaryEvidence
    }
}

/// Protocol isolating physical movement classification with hysteresis.
public protocol MovementClassifying: Sendable {
    func classify(
        evidence: MovementEvidence,
        previousState: MovementState,
        consecutiveMovingEvidence: Int,
        consecutiveStationaryEvidence: Int,
        configuration: GPSProcessingConfiguration
    ) -> MovementClassificationResult
}

/// Standard movement classifier implementing asymmetric hysteresis.
public struct MovementClassifier: MovementClassifying, Sendable {
    public init() {}

    public func classify(
        evidence: MovementEvidence,
        previousState: MovementState,
        consecutiveMovingEvidence: Int,
        consecutiveStationaryEvidence: Int,
        configuration: GPSProcessingConfiguration
    ) -> MovementClassificationResult {
        let speed = evidence.selectedSpeedMetersPerSecond
        let dist = evidence.positionDistanceMeters
        let accuracyOverlap = evidence.accuracyOverlap

        var isMovingEvidence = false
        var isStationaryEvidence = false

        if let spd = speed {
            if spd >= configuration.movingSpeedThresholdMetersPerSecond &&
                (dist >= configuration.minimumMovementDistanceMeters || !accuracyOverlap) {
                isMovingEvidence = true
            } else if spd <= configuration.stationarySpeedThresholdMetersPerSecond && accuracyOverlap {
                isStationaryEvidence = true
            }
        } else {
            // Speed unavailable: rely on position delta and accuracy overlap
            if dist >= configuration.minimumMovementDistanceMeters && !accuracyOverlap {
                isMovingEvidence = true
            } else if accuracyOverlap {
                isStationaryEvidence = true
            }
        }

        var movingStreak = consecutiveMovingEvidence
        var stationaryStreak = consecutiveStationaryEvidence
        var nextState = previousState

        if isMovingEvidence {
            movingStreak += 1
            stationaryStreak = 0
            if movingStreak >= configuration.movementConfirmationSamples {
                nextState = .moving
            }
        } else if isStationaryEvidence {
            stationaryStreak += 1
            movingStreak = 0
            if stationaryStreak >= configuration.stationaryConfirmationSamples {
                nextState = .stationary
            }
        } else {
            // Ambiguous: retain existing streaks or decay
            if previousState == .unknown {
                nextState = .unknown
            }
        }

        return MovementClassificationResult(
            state: nextState,
            consecutiveMovingEvidence: movingStreak,
            consecutiveStationaryEvidence: stationaryStreak
        )
    }
}
