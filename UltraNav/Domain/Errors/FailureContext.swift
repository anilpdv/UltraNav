import Foundation

enum FailureOperation: Equatable, Hashable, Sendable {
    case appStartup
    case ridePreparation
    case rideStart
    case ridePause
    case rideResume
    case rideFinish
    case locationAuthorization
    case locationUpdates
    case workoutAuthorization
    case workoutPreparation
    case workoutFinalization
    case sensorScan
    case sensorConnection
    case sensorMeasurement
    case routeImport
    case routeLoad
    case routeSave
    case routeDelete
    case navigationMatching
    case navigationProgress
    case navigationRejoin
    case metricProcessing
    case climbAnalysis
    case climbProgress
}

struct FailureContext: Equatable, Sendable {
    let occurredAt: Date
    let operation: FailureOperation
    let rideState: RideStateName?
    let navigationState: NavigationStateName?
    let routeID: Route.ID?
    let sensorID: SensorIdentifier?
    let isUserInitiated: Bool
    let attempt: Int?

    init(
        occurredAt: Date = Date(),
        operation: FailureOperation,
        rideState: RideStateName? = nil,
        navigationState: NavigationStateName? = nil,
        routeID: Route.ID? = nil,
        sensorID: SensorIdentifier? = nil,
        isUserInitiated: Bool = false,
        attempt: Int? = nil
    ) {
        self.occurredAt = occurredAt
        self.operation = operation
        self.rideState = rideState
        self.navigationState = navigationState
        self.routeID = routeID
        self.sensorID = sensorID
        self.isUserInitiated = isUserInitiated
        self.attempt = attempt
    }
}
