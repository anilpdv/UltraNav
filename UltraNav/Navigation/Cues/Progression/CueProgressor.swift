import Foundation

/// Configuration parameters for cue progression and alert thresholding.
struct CueProgressionConfiguration: Equatable, Sendable {
    var approachThresholdMeters: Double
    var immediateThresholdMeters: Double
    var passedThresholdMeters: Double

    init(
        approachThresholdMeters: Double = 100.0,
        immediateThresholdMeters: Double = 25.0,
        passedThresholdMeters: Double = 15.0
    ) {
        self.approachThresholdMeters = approachThresholdMeters
        self.immediateThresholdMeters = immediateThresholdMeters
        self.passedThresholdMeters = passedThresholdMeters
    }
}

/// Manages deterministic cue advancement, phase classification, and exactly-once notification emission.
struct CueProgressor: CueProgressing, Sendable {
    let configuration: CueProgressionConfiguration

    init(configuration: CueProgressionConfiguration = CueProgressionConfiguration()) {
        self.configuration = configuration
    }

    func progress(
        cues: [NavigationCue],
        routeMatch: RouteMatch,
        previous: CueProgress?
    ) -> CueProgress {
        guard !cues.isEmpty else {
            return CueProgress()
        }

        // Ambiguous match or severe off-track maintains previous progression without advancing
        if routeMatch.confidence == .ambiguous || (routeMatch.confidence == .low && routeMatch.crossTrackDistanceMeters > 50.0) {
            return previous ?? CueProgress(nextCue: cues.first, distanceToNextCueMeters: cues.first?.routeDistanceMeters)
        }

        let userDist = routeMatch.distanceAlongRouteMeters
        var passedIDs = previous?.passedCueIDs ?? Set<NavigationCue.ID>()
        var approachedIDs = previous?.approachedCueIDs ?? Set<NavigationCue.ID>()
        var immediateIDs = previous?.immediateAlertedCueIDs ?? Set<NavigationCue.ID>()
        var pendingNotification: NavigationNotification?

        // Advance passed cues monotonically (backtracking does NOT unpass cues)
        for cue in cues {
            if userDist >= (cue.routeDistanceMeters + configuration.passedThresholdMeters) {
                passedIDs.insert(cue.id)
            }
        }

        // Locate next active unpassed cue
        guard let nextCue = cues.first(where: { !passedIDs.contains($0.id) }) else {
            return CueProgress(
                nextCue: nil,
                distanceToNextCueMeters: nil,
                passedCueIDs: passedIDs,
                approachedCueIDs: approachedIDs,
                immediateAlertedCueIDs: immediateIDs,
                phase: .passed,
                pendingNotification: nil
            )
        }

        let distanceToCue = max(0.0, nextCue.routeDistanceMeters - userDist)
        let phase: CuePhase

        if distanceToCue <= configuration.immediateThresholdMeters {
            phase = .immediate
            if !immediateIDs.contains(nextCue.id) {
                immediateIDs.insert(nextCue.id)
                pendingNotification = .immediateCue(nextCue)
            }
        } else if distanceToCue <= configuration.approachThresholdMeters {
            phase = .approaching
            if !approachedIDs.contains(nextCue.id) {
                approachedIDs.insert(nextCue.id)
                pendingNotification = .approachingCue(nextCue)
            }
        } else {
            phase = .distant
        }

        return CueProgress(
            nextCue: nextCue,
            distanceToNextCueMeters: distanceToCue,
            passedCueIDs: passedIDs,
            approachedCueIDs: approachedIDs,
            immediateAlertedCueIDs: immediateIDs,
            phase: phase,
            pendingNotification: pendingNotification
        )
    }
}
