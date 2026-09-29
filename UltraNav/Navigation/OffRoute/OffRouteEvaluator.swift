import Foundation

/// Evaluates route match telemetry to deterministically detect off-route deviations and rejoins.
final class OffRouteEvaluator: OffRouteEvaluating, @unchecked Sendable {
    let configuration: OffRouteConfiguration
    private var evidence: OffRouteEvidence

    init(configuration: OffRouteConfiguration = OffRouteConfiguration()) {
        self.configuration = configuration
        self.evidence = OffRouteEvidence()
    }

    func evaluate(
        match: RouteMatch,
        previousStatus: OffRouteStatus,
        timestamp: Date
    ) -> OffRouteEvaluation {
        let crossTrack = match.crossTrackDistanceMeters
        let headingDiff = match.headingDifferenceDegrees ?? 0.0

        let isSevereAngleMismatch = headingDiff > configuration.maximumHeadingDifferenceDegrees && match.confidence != .high
        let effectiveCrossTrack = isSevereAngleMismatch ? crossTrack * 1.5 : crossTrack

        switch previousStatus {
        case .onRoute, .unknown:
            if effectiveCrossTrack > configuration.confirmedDistanceThresholdMeters {
                evidence.recordDeviation(at: timestamp)
                if evidence.consecutiveOffTrackCount >= configuration.consecutiveEvidenceCount ||
                    evidence.deviationDuration(currentTimestamp: timestamp) >= configuration.confirmationDurationSeconds {
                    return OffRouteEvaluation(status: .offRoute, shouldNotify: true)
                } else {
                    return OffRouteEvaluation(status: .suspected, shouldNotify: false)
                }
            } else if effectiveCrossTrack > configuration.suspectedDistanceThresholdMeters {
                evidence.recordDeviation(at: timestamp)
                return OffRouteEvaluation(status: .suspected, shouldNotify: false)
            } else {
                evidence.recordRecovery()
                return OffRouteEvaluation(status: .onRoute, shouldNotify: false)
            }

        case .suspected:
            if effectiveCrossTrack > configuration.confirmedDistanceThresholdMeters {
                evidence.recordDeviation(at: timestamp)
                if evidence.consecutiveOffTrackCount >= configuration.consecutiveEvidenceCount ||
                    evidence.deviationDuration(currentTimestamp: timestamp) >= configuration.confirmationDurationSeconds {
                    return OffRouteEvaluation(status: .offRoute, shouldNotify: true)
                } else {
                    return OffRouteEvaluation(status: .suspected, shouldNotify: false)
                }
            } else if effectiveCrossTrack <= configuration.recoveryDistanceThresholdMeters {
                evidence.recordRecovery()
                return OffRouteEvaluation(status: .onRoute, shouldNotify: false)
            } else {
                return OffRouteEvaluation(status: .suspected, shouldNotify: false)
            }

        case .offRoute:
            if effectiveCrossTrack <= configuration.recoveryDistanceThresholdMeters {
                evidence.recordRecovery()
                if evidence.consecutiveRecoveryCount >= 2 {
                    return OffRouteEvaluation(status: .onRoute, shouldNotify: true)
                } else {
                    return OffRouteEvaluation(status: .rejoining, shouldNotify: false)
                }
            } else if effectiveCrossTrack <= configuration.suspectedDistanceThresholdMeters {
                return OffRouteEvaluation(status: .rejoining, shouldNotify: false)
            } else {
                return OffRouteEvaluation(status: .offRoute, shouldNotify: false)
            }

        case .rejoining:
            if effectiveCrossTrack <= configuration.recoveryDistanceThresholdMeters {
                evidence.recordRecovery()
                return OffRouteEvaluation(status: .onRoute, shouldNotify: true)
            } else if effectiveCrossTrack > configuration.confirmedDistanceThresholdMeters {
                evidence.recordDeviation(at: timestamp)
                return OffRouteEvaluation(status: .offRoute, shouldNotify: true)
            } else {
                return OffRouteEvaluation(status: .rejoining, shouldNotify: false)
            }
        }
    }

    func reset() {
        evidence.reset()
    }
}
