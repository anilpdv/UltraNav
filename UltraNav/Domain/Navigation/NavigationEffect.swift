import Foundation

enum NavigationEffect: Equatable, Sendable {
    case loadRoute
    case initializeNavigation
    case notifyPossibleDeviation
    case notifyOffRoute
    case notifyRouteRejoined
    case finishNavigation
    case clearNavigation
}
