import Foundation

enum NavigationNotification: Equatable, Sendable {
    case approachingCue(NavigationCue)
    case immediateCue(NavigationCue)
    case possibleDeviation
    case offRoute
    case routeRejoined
    case routeCompleted
}
