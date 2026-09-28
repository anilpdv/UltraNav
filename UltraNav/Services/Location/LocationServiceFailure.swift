import Foundation

enum LocationServiceFailure: Error, Equatable, Sendable {
    case authorizationDenied
    case authorizationRestricted
    case servicesDisabled
    case updatesUnavailable
    case updateFailed
    case alreadyRunning
    case unexpected
}
