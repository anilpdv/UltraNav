import Foundation

enum NavigationEffect: Equatable, Sendable {
    case loadRoute
    case initializeNavigation
    case notifyOffRoute
    case notifyRouteRejoined
    case stopNavigation
    case finishNavigation
    case clearNavigation
}
