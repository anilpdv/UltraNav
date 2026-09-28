import Foundation

enum RouteStoreError: Error, Equatable, Sendable {
    case routeNotFound
    case duplicateRoute
    case invalidRoute
    case readFailed
    case writeFailed
    case deleteFailed
    case storageUnavailable
    case unexpected
}
