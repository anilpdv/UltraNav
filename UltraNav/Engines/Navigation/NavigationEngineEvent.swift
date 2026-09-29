import Foundation

enum NavigationEngineEvent: Equatable, Sendable {
    case command(NavigationEngineCommand)
    case locationReceived(LocationSample)
    case routeLoaded(Route)
    case routeLoadFailed(NavigationFailure)
}
