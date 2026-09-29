import Foundation

/// Strongly typed failures published by RouteLibraryEngine.
public enum RouteLibraryFailure: Error, Equatable, Sendable {
    case loadFailed(String)
    case importFailed(RouteImportFailure)
    case deleteFailed(String)
    case activeRouteProtected(Route.ID)
}
