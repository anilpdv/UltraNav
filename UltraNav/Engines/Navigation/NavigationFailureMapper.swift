import Foundation

struct NavigationFailureMapper: Sendable {
    func map(_ error: Error) -> NavigationFailure {
        if let failure = error as? NavigationFailure {
            return failure
        }
        if let routeStoreError = error as? RouteStoreError {
            switch routeStoreError {
            case .routeNotFound:
                return .routeUnavailable
            case .invalidRoute:
                return .invalidRoute
            case .storageUnavailable, .readFailed, .writeFailed, .deleteFailed, .duplicateRoute, .activeRouteProtected, .invalidStorageRecord, .corruptedIndexRebuilt, .unexpected:
                return .routeUnavailable
            }
        }
        if error is NavigationRouteValidationFailure {
            return .invalidRoute
        }
        return .routeUnavailable
    }
}
