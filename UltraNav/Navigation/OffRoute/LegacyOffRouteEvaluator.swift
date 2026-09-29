import Foundation

struct LegacyOffRouteEvaluator: OffRouteEvaluating, Sendable {
    let thresholdMeters: Double
    let recoveryThresholdMeters: Double

    init(
        thresholdMeters: Double = 35.0,
        recoveryThresholdMeters: Double = 25.0
    ) {
        self.thresholdMeters = thresholdMeters
        self.recoveryThresholdMeters = recoveryThresholdMeters
    }

    func evaluate(
        match: RouteMatch,
        previousStatus: OffRouteStatus,
        timestamp: Date
    ) -> OffRouteEvaluation {
        // Legacy fixed-threshold hysteresis: 35m off-route, 25m recovery
        // TODO(PHASE-7): Replace with GPS-accuracy-aware adaptive thresholds, persistent confirmation, and rejoin modeling
        let crossTrack = match.crossTrackDistanceMeters

        if previousStatus == .offRoute {
            if crossTrack <= recoveryThresholdMeters {
                return OffRouteEvaluation(status: .onRoute, shouldNotify: true)
            } else if crossTrack <= thresholdMeters {
                return OffRouteEvaluation(status: .rejoining, shouldNotify: false)
            } else {
                return OffRouteEvaluation(status: .offRoute, shouldNotify: false)
            }
        } else if previousStatus == .rejoining {
            if crossTrack <= recoveryThresholdMeters {
                return OffRouteEvaluation(status: .onRoute, shouldNotify: true)
            } else if crossTrack > thresholdMeters {
                return OffRouteEvaluation(status: .offRoute, shouldNotify: true)
            } else {
                return OffRouteEvaluation(status: .rejoining, shouldNotify: false)
            }
        } else {
            if crossTrack > thresholdMeters {
                return OffRouteEvaluation(status: .offRoute, shouldNotify: true)
            } else if crossTrack > recoveryThresholdMeters {
                return OffRouteEvaluation(status: .suspected, shouldNotify: false)
            } else {
                return OffRouteEvaluation(status: .onRoute, shouldNotify: false)
            }
        }
    }
}
