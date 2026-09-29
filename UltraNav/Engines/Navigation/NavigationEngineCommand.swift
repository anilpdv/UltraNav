import Foundation

enum NavigationEngineCommand: Equatable, Sendable {
    case loadRoute(Route.ID)
    case useRoute(Route)
    case start
    case stop
    case clearRoute
    case recover
    case reset
}
