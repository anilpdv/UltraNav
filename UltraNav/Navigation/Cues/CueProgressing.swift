import Foundation

struct CueProgress: Equatable, Sendable {
    let nextCue: NavigationCue?
    let distanceToNextCueMeters: Double?
    let passedCueIDs: Set<NavigationCue.ID>

    init(
        nextCue: NavigationCue? = nil,
        distanceToNextCueMeters: Double? = nil,
        passedCueIDs: Set<NavigationCue.ID> = []
    ) {
        self.nextCue = nextCue
        self.distanceToNextCueMeters = distanceToNextCueMeters
        self.passedCueIDs = passedCueIDs
    }
}

protocol CueProgressing: Sendable {
    func progress(
        cues: [NavigationCue],
        routeMatch: RouteMatch,
        previous: CueProgress?
    ) -> CueProgress
}
