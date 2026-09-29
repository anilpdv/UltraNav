import Foundation

struct NavigationRouteState: Equatable, Sendable {
    private(set) var route: Route?
    private(set) var cues: [NavigationCue] = []

    mutating func load(
        route: Route,
        cues: [NavigationCue]
    ) {
        self.route = route
        self.cues = cues
    }

    mutating func clear() {
        route = nil
        cues = []
    }
}
