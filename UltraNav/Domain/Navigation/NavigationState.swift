import Foundation

enum NavigationState: Equatable, Sendable {
    case inactive
    case loading
    case ready
    case navigating
    case offRoute
    case finished
    case failed(NavigationFailure)
}
