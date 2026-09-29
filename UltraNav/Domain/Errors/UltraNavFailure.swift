import Foundation

enum UltraNavFailure: Error, Equatable, Sendable {
    case app(AppFailure)
    case ride(RideFailure)
    case location(LocationServiceFailure)
    case workout(WorkoutServiceFailure)
    case sensors(SensorServiceFailure)
    case routeImport(RouteImportFailure)
    case routeStore(RouteStoreError)
    case navigation(NavigationFailure)
    case metrics(MetricsFailure)
    case climb(ClimbFailure)
}
