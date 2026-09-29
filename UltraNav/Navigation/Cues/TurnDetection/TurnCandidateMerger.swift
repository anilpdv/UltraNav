import Foundation

/// Merges closely spaced turn candidates to handle compound turns and prevent duplicate cue alerts.
struct TurnCandidateMerger: Sendable {
    let clusterThresholdMeters: Double

    init(clusterThresholdMeters: Double = 25.0) {
        self.clusterThresholdMeters = clusterThresholdMeters
    }

    /// Merges an array of candidates into a simplified, non-redundant sequence of turns.
    func merge(candidates: [TurnCandidate]) -> [TurnCandidate] {
        guard candidates.count > 1 else { return candidates }

        var merged: [TurnCandidate] = []
        var currentCluster: [TurnCandidate] = [candidates[0]]

        for i in 1..<candidates.count {
            let nextCandidate = candidates[i]
            let prevCandidate = currentCluster.last!

            let distanceDelta = nextCandidate.distanceAlongRouteMeters - prevCandidate.distanceAlongRouteMeters

            if distanceDelta <= clusterThresholdMeters {
                currentCluster.append(nextCandidate)
            } else {
                merged.append(collapseCluster(currentCluster))
                currentCluster = [nextCandidate]
            }
        }

        if !currentCluster.isEmpty {
            merged.append(collapseCluster(currentCluster))
        }

        return merged.filter { $0.maneuver != .continueStraight }
    }

    private func collapseCluster(_ cluster: [TurnCandidate]) -> TurnCandidate {
        if cluster.count == 1 { return cluster[0] }

        // Net angle of cluster
        var netAngle: Double = 0.0
        for item in cluster {
            netAngle += item.turnAngleDegrees
        }
        netAngle = ManeuverClassifier.normalizeAngleDifference(netAngle)

        // Select the dominant candidate with the highest magnitude
        let dominant = cluster.max(by: { abs($0.turnAngleDegrees) < abs($1.turnAngleDegrees) }) ?? cluster[0]
        let classifiedManeuver = ManeuverClassifier.classify(turnAngleDegrees: netAngle)

        return TurnCandidate(
            distanceAlongRouteMeters: dominant.distanceAlongRouteMeters,
            coordinate: dominant.coordinate,
            turnAngleDegrees: netAngle,
            maneuver: classifiedManeuver
        )
    }
}
