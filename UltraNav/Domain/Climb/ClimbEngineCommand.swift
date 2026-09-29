import Foundation

/// Inbound commands processed by ClimbEngine.
enum ClimbEngineCommand: Equatable, Sendable {
    case loadRoute(Route)
    case processNavigation(NavigationSnapshot)
    case processLocation(LocationSample)
    case reset
}
