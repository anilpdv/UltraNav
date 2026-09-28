import Foundation

enum RidePersistenceError: Error,
                           Equatable,
                           Sendable {
    case rideNotFound
    case readFailed
    case writeFailed
    case deleteFailed
    case storageUnavailable
    case unexpected
}
