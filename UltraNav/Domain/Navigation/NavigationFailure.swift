import Foundation

enum NavigationFailure: Error, Equatable, Sendable {
    case invalidRoute
    case routeUnavailable
    case locationUnavailable
    case calculationFailed
    case unexpected
}
