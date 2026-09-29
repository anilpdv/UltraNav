import Foundation

@MainActor
final class RecoveryCoordinator: FailureRecovering {
    private let rideLifecycle: any RideLifecycleCoordinating
    private let routeNavigation: RouteNavigationCoordinator
    private let sensors: any SensorProviding
    private let location: any LocationProviding
    private let workout: any WorkoutProviding
    private let failureRecorder: any FailureRecording
    private let policy: any RecoveryPolicy

    init(
        rideLifecycle: any RideLifecycleCoordinating,
        routeNavigation: RouteNavigationCoordinator,
        sensors: any SensorProviding,
        location: any LocationProviding,
        workout: any WorkoutProviding,
        failureRecorder: any FailureRecording,
        policy: any RecoveryPolicy = StandardRecoveryPolicy()
    ) {
        self.rideLifecycle = rideLifecycle
        self.routeNavigation = routeNavigation
        self.sensors = sensors
        self.location = location
        self.workout = workout
        self.failureRecorder = failureRecorder
        self.policy = policy
    }

    func perform(action: RecoveryAction, for record: FailureRecord) async -> RecoveryResult {
        switch action {
        case .retry:
            return await executeRetry(for: record)

        case .retryAfterDelay:
            let recommendation = policy.recommendation(for: record.failure, context: record.context)
            let attempt = (record.context.attempt ?? 0) + 1
            if let delay = recommendation.automaticRetry?.delay(forAttempt: attempt) {
                return .retryScheduled(attempt: attempt, delaySeconds: delay)
            } else {
                return .operationAbandoned
            }

        case .continueWithoutSensors:
            return .recoveredWithDegradation(.sensorsUnavailable)

        case .continueWithoutNavigation:
            await routeNavigation.clearRoute()
            return .recoveredWithDegradation(.navigationUnavailable)

        case .continueWithoutClimbData:
            return .recoveredWithDegradation(.climbDataUnavailable)

        case .selectAnotherRoute:
            await routeNavigation.clearRoute()
            return .userActionRequired([.selectAnotherRoute])

        case .requestLocationPermission:
            await location.requestAuthorization()
            return .userActionRequired([.retry])

        case .requestHealthPermission:
            do {
                try await workout.requestAuthorization()
                return .recovered
            } catch {
                return .failed(.workout(.authorizationFailed))
            }

        case .openSystemSettings:
            return .userActionRequired([.openSystemSettings])

        case .reconnectSensor(let sensorID):
            do {
                try await sensors.connect(to: sensorID)
                return .recovered
            } catch {
                if let sensorFailure = error as? SensorServiceFailure {
                    return .failed(.sensors(sensorFailure))
                }
                return .failed(.sensors(.connectionFailed(sensorID)))
            }

        case .finishRideWithoutHealthKitSave:
            await rideLifecycle.finish()
            return .recoveredWithDegradation(.workoutNotSaved)

        case .saveRideLocally:
            return .recoveredWithDegradation(.workoutNotSaved)

        case .resetSubsystem:
            return .recovered

        case .resetRide:
            await rideLifecycle.reset()
            return .recovered

        case .dismiss:
            return .operationAbandoned

        case .contactSupport:
            return .userActionRequired([.contactSupport])
        }
    }

    private func executeRetry(for record: FailureRecord) async -> RecoveryResult {
        switch record.context.operation {
        case .ridePreparation:
            await rideLifecycle.prepare()
            return .recovered

        case .rideStart:
            await rideLifecycle.start()
            return .recovered

        case .ridePause:
            await rideLifecycle.pause()
            return .recovered

        case .rideResume:
            await rideLifecycle.resume()
            return .recovered

        case .rideFinish:
            await rideLifecycle.finish()
            return .recovered

        case .locationAuthorization:
            await location.requestAuthorization()
            return .recovered

        case .locationUpdates:
            do {
                try await location.startUpdates()
                return .recovered
            } catch {
                return .failed(.location(.updateFailed))
            }

        case .workoutAuthorization:
            do {
                try await workout.requestAuthorization()
                return .recovered
            } catch {
                return .failed(.workout(.authorizationFailed))
            }

        case .workoutPreparation:
            do {
                try await workout.prepare()
                return .recovered
            } catch {
                return .failed(.workout(.preparationFailed))
            }

        case .sensorConnection:
            if let sensorID = record.context.sensorID {
                do {
                    try await sensors.connect(to: sensorID)
                    return .recovered
                } catch {
                    return .failed(.sensors(.connectionFailed(sensorID)))
                }
            }
            return .operationAbandoned

        case .routeLoad:
            if let routeID = record.context.routeID {
                await routeNavigation.selectRoute(id: routeID)
                return .recovered
            }
            return .operationAbandoned

        default:
            return .operationAbandoned
        }
    }
}
