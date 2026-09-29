import Foundation

enum AppFailure: Error, Equatable, Sendable {
    case dependencyConstructionFailed
    case routeStorageUnavailable
    case routeMigrationFailed
    case invalidConfiguration
    case essentialServiceUnavailable
    case unexpected
}
