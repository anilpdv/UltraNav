import Foundation

/// Commands that can be dispatched to RouteLibraryEngine.
public enum RouteLibraryCommand: Equatable, Sendable {
    case load
    case refresh
    case importSource(RouteImportSource, policy: RouteImportPolicy = .default)
    case deleteRoute(Route.ID)
    case selectRoute(Route.ID?)
    case setActiveRoute(Route.ID?)
    case clearFailure
}

/// Protocol defining the presentation contract of the route library.
@MainActor
public protocol RouteLibraryProviding: AnyObject, Sendable {
    var currentSnapshot: RouteLibrarySnapshot { get }
    var snapshots: AsyncStream<RouteLibrarySnapshot> { get }

    func send(_ command: RouteLibraryCommand) async
}
