import Foundation

enum LogCategory: String, CaseIterable, Sendable {
    case app
    case dependencyInjection
    case ride
    case location
    case workout
    case bluetooth
    case routeImport
    case routeStore
    case navigation
    case metrics
    case climb
    case presentation
    case recovery
    case concurrency
    case observability
}
