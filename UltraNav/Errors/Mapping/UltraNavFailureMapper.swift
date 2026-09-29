import Foundation

struct UltraNavFailureMapper: FailureClassifying {
    typealias Failure = UltraNavFailure

    private let appMapper = AppFailureMapper()
    private let rideMapper = RideFailureMapper()
    private let locationMapper = LocationServiceFailureMapper()
    private let workoutMapper = WorkoutServiceFailureMapper()
    private let sensorMapper = SensorServiceFailureMapper()
    private let routeMapper = RouteFailureMapper()
    private let navigationMapper = NavigationFailureMapper()
    private let metricsMapper = MetricsFailureMapper()
    private let climbMapper = ClimbFailureMapper()

    func classify(failure: UltraNavFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .app(let appFailure):
            return appMapper.classify(failure: appFailure, context: context)
        case .ride(let rideFailure):
            return rideMapper.classify(failure: rideFailure, context: context)
        case .location(let locationFailure):
            return locationMapper.classify(failure: locationFailure, context: context)
        case .workout(let workoutFailure):
            return workoutMapper.classify(failure: workoutFailure, context: context)
        case .sensors(let sensorFailure):
            return sensorMapper.classify(failure: sensorFailure, context: context)
        case .routeImport, .routeStore:
            return routeMapper.classify(failure: failure, context: context)
        case .navigation(let navFailure):
            return navigationMapper.classify(failure: navFailure, context: context)
        case .metrics(let metricFailure):
            return metricsMapper.classify(failure: metricFailure, context: context)
        case .climb(let climbFailure):
            return climbMapper.classify(failure: climbFailure, context: context)
        }
    }
}
