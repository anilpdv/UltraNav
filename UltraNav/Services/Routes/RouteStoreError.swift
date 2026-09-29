import Foundation

/// Errors that can occur when reading, saving, indexing, or deleting routes in storage.
public enum RouteStoreError: Error, Equatable, Sendable {
    case routeNotFound(Route.ID)
    case duplicateRoute(Route.ID)
    case activeRouteProtected(Route.ID)
    case invalidRoute
    case invalidStorageRecord(String)
    case readFailed(String)
    case writeFailed(String)
    case deleteFailed(String)
    case storageUnavailable
    case corruptedIndexRebuilt
    case unexpected

    public static func == (lhs: RouteStoreError, rhs: RouteStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.routeNotFound(let id1), .routeNotFound(let id2)):
            return id1 == id2
        case (.duplicateRoute(let id1), .duplicateRoute(let id2)):
            return id1 == id2
        case (.activeRouteProtected(let id1), .activeRouteProtected(let id2)):
            return id1 == id2
        case (.invalidRoute, .invalidRoute):
            return true
        case (.invalidStorageRecord(let m1), .invalidStorageRecord(let m2)):
            return m1 == m2
        case (.readFailed(let m1), .readFailed(let m2)):
            return m1 == m2
        case (.writeFailed(let m1), .writeFailed(let m2)):
            return m1 == m2
        case (.deleteFailed(let m1), .deleteFailed(let m2)):
            return m1 == m2
        case (.storageUnavailable, .storageUnavailable):
            return true
        case (.corruptedIndexRebuilt, .corruptedIndexRebuilt):
            return true
        case (.unexpected, .unexpected):
            return true
        default:
            return false
        }
    }
}
