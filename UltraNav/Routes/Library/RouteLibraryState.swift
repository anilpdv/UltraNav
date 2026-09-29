import Foundation

/// Lifecycle states of the Route Library Engine.
public enum RouteLibraryState: Equatable, Sendable {
    case idle
    case loading
    case ready
    case importing
    case deleting
    case failed(RouteLibraryFailure)
}
