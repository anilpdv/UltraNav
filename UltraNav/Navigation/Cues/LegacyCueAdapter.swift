import Foundation

struct LegacyCueAdapter: NavigationCueProviding, CueProgressing, Sendable {
    func cues(for route: Route) throws -> [NavigationCue] {
        // Legacy implementation uses cues embedded in the source route if any
        // TODO(PHASE-6): Implement automated turn generation and cue synthesis
        return []
    }

    func progress(
        cues: [NavigationCue],
        routeMatch: RouteMatch,
        previous: CueProgress?
    ) -> CueProgress {
        guard !cues.isEmpty else {
            return CueProgress(nextCue: nil, distanceToNextCueMeters: nil, passedCueIDs: [])
        }

        let userProgressDist = routeMatch.distanceAlongRouteMeters
        var passedIDs = previous?.passedCueIDs ?? Set<NavigationCue.ID>()

        for cue in cues {
            if cue.routeDistanceMeters < userProgressDist {
                passedIDs.insert(cue.id)
            }
        }

        // Find upcoming cue (legacy 25m lookahead window)
        // TODO(PHASE-6): Implement smooth cue progression, hysteresis, and multi-cue lookahead
        if let upcoming = cues.first(where: { $0.routeDistanceMeters >= (userProgressDist - 25) }) {
            let dist = max(0, upcoming.routeDistanceMeters - userProgressDist)
            return CueProgress(
                nextCue: upcoming,
                distanceToNextCueMeters: dist,
                passedCueIDs: passedIDs
            )
        } else if let last = cues.last {
            let dist = max(0, last.routeDistanceMeters - userProgressDist)
            return CueProgress(
                nextCue: last,
                distanceToNextCueMeters: dist,
                passedCueIDs: passedIDs
            )
        }

        return CueProgress(nextCue: nil, distanceToNextCueMeters: nil, passedCueIDs: passedIDs)
    }
}
