import Foundation

enum CuePhase: String, Equatable, Sendable {
    case idle
    case distant
    case approaching
    case immediate
    case passed
}

struct CueProgress: Equatable, Sendable {
    let nextCue: NavigationCue?
    let distanceToNextCueMeters: Double?
    let passedCueIDs: Set<NavigationCue.ID>
    let approachedCueIDs: Set<NavigationCue.ID>
    let immediateAlertedCueIDs: Set<NavigationCue.ID>
    let phase: CuePhase
    let pendingNotification: NavigationNotification?

    init(
        nextCue: NavigationCue? = nil,
        distanceToNextCueMeters: Double? = nil,
        passedCueIDs: Set<NavigationCue.ID> = [],
        approachedCueIDs: Set<NavigationCue.ID> = [],
        immediateAlertedCueIDs: Set<NavigationCue.ID> = [],
        phase: CuePhase = .idle,
        pendingNotification: NavigationNotification? = nil
    ) {
        self.nextCue = nextCue
        self.distanceToNextCueMeters = distanceToNextCueMeters
        self.passedCueIDs = passedCueIDs
        self.approachedCueIDs = approachedCueIDs
        self.immediateAlertedCueIDs = immediateAlertedCueIDs
        self.phase = phase
        self.pendingNotification = pendingNotification
    }
}

protocol CueProgressing: Sendable {
    func progress(
        cues: [NavigationCue],
        routeMatch: RouteMatch,
        previous: CueProgress?
    ) -> CueProgress
}
