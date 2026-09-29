import Foundation

struct LocationServiceFailureMapper: FailureClassifying {
    typealias Failure = LocationServiceFailure

    func classify(failure: LocationServiceFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .authorizationDenied, .authorizationRestricted:
            return FailureClassification(
                id: .locationPermissionDenied,
                severity: context.rideState == .active ? .critical : .high,
                impact: [.blocksRidePreparation, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.openSystemSettings, .requestLocationPermission],
                diagnosticMessage: "Location authorization denied/restricted"
            )

        case .servicesDisabled:
            return FailureClassification(
                id: .locationServiceDisabled,
                severity: .high,
                impact: [.blocksRidePreparation, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.openSystemSettings],
                diagnosticMessage: "Location services disabled system-wide"
            )

        case .updatesUnavailable, .updateFailed:
            return FailureClassification(
                id: .locationUpdateFailed,
                severity: context.rideState == .active ? .warning : .high,
                impact: context.rideState == .active ? .degradesActiveRide : .blocksRidePreparation,
                recoverability: context.rideState == .active ? .recoverableWithDegradation : .retryable,
                suggestedActions: context.rideState == .active ? [.dismiss] : [.retry],
                diagnosticMessage: "Location updates failed"
            )

        case .alreadyRunning:
            return FailureClassification(
                id: FailureID(rawValue: "LOCATION-STATE-001"),
                severity: .informational,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Location service already running"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "LOCATION-UNEXPECTED-001"),
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Unexpected location service failure"
            )
        }
    }
}

struct WorkoutServiceFailureMapper: FailureClassifying {
    typealias Failure = WorkoutServiceFailure

    func classify(failure: WorkoutServiceFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .healthDataUnavailable, .authorizationDenied, .authorizationRequired, .authorizationFailed:
            return FailureClassification(
                id: .workoutAuthorizationDenied,
                severity: .high,
                impact: [.blocksRidePreparation, .blocksRideStart, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.openSystemSettings, .requestHealthPermission],
                diagnosticMessage: "HealthKit authorization unavailable/denied"
            )

        case .configurationFailed, .sessionCreationFailed, .builderCreationFailed, .preparationFailed:
            return FailureClassification(
                id: .workoutPreparationFailed,
                severity: .high,
                impact: [.blocksRidePreparation, .blocksRideStart],
                recoverability: .retryable,
                suggestedActions: [.retry, .resetRide],
                diagnosticMessage: "Workout session/builder initialization failed"
            )

        case .startFailed, .collectionStartFailed:
            return FailureClassification(
                id: .workoutStartFailed,
                severity: .critical,
                impact: [.blocksRideStart, .threatensRidePersistence],
                recoverability: .retryable,
                suggestedActions: [.retry, .resetRide],
                diagnosticMessage: "Workout session start failed"
            )

        case .pauseFailed, .resumeFailed:
            return FailureClassification(
                id: .workoutPauseFailed,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Workout pause/resume failed"
            )

        case .collectionEndFailed, .workoutSaveFailed, .finishFailed:
            return FailureClassification(
                id: .workoutSaveFailed,
                severity: .high,
                impact: [.threatensRidePersistence, .requiresUserAttention],
                recoverability: .retryable,
                suggestedActions: [.retry, .saveRideLocally, .finishRideWithoutHealthKitSave],
                diagnosticMessage: "Workout finalization or HealthKit save failed"
            )

        case .unexpectedSessionEnd, .competingWorkoutDetected:
            return FailureClassification(
                id: .workoutSessionTerminated,
                severity: .critical,
                impact: [.threatensRidePersistence, .requiresUserAttention],
                recoverability: .recoverableWithDegradation,
                suggestedActions: [.saveRideLocally, .dismiss],
                diagnosticMessage: "Workout session terminated externally or by competing workout"
            )

        case .invalidServiceState, .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "WORKOUT-UNEXPECTED-001"),
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.resetSubsystem, .dismiss],
                diagnosticMessage: "Unexpected workout service error"
            )
        }
    }
}

struct SensorServiceFailureMapper: FailureClassifying {
    typealias Failure = SensorServiceFailure

    func classify(failure: SensorServiceFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .bluetoothUnavailable:
            return FailureClassification(
                id: .bluetoothUnavailable,
                severity: .warning,
                impact: .blocksSensors,
                recoverability: .userActionRequired,
                suggestedActions: [.continueWithoutSensors, .openSystemSettings],
                diagnosticMessage: "CoreBluetooth is unavailable or powered off"
            )

        case .scanFailed:
            return FailureClassification(
                id: .sensorScanFailed,
                severity: .warning,
                impact: .blocksSensors,
                recoverability: .retryable,
                suggestedActions: [.retry, .continueWithoutSensors],
                diagnosticMessage: "Bluetooth peripheral scan failed"
            )

        case .unknownSensor:
            return FailureClassification(
                id: .sensorConnectionFailed,
                severity: .warning,
                impact: .blocksSensors,
                recoverability: .retryable,
                suggestedActions: [.continueWithoutSensors],
                diagnosticMessage: "Unknown sensor requested"
            )

        case .connectionFailed(let id):
            return FailureClassification(
                id: .sensorConnectionFailed,
                severity: .warning,
                impact: .blocksSensors,
                recoverability: .retryable,
                suggestedActions: [.reconnectSensor(id), .continueWithoutSensors],
                diagnosticMessage: "Failed to connect to sensor \(id)"
            )

        case .disconnectedUnexpectedly(let id):
            return FailureClassification(
                id: .sensorDisconnected,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.reconnectSensor(id), .continueWithoutSensors],
                diagnosticMessage: "Sensor \(id) disconnected unexpectedly"
            )

        case .serviceDiscoveryFailed, .requiredServiceMissing, .characteristicDiscoveryFailed, .requiredCharacteristicMissing, .notificationSetupFailed:
            return FailureClassification(
                id: .sensorConnectionFailed,
                severity: .warning,
                impact: .blocksSensors,
                recoverability: .retryable,
                suggestedActions: [.retry, .continueWithoutSensors],
                diagnosticMessage: "Bluetooth GATT service/characteristic discovery or notification setup failed"
            )

        case .malformedMeasurement:
            return FailureClassification(
                id: .sensorMalformedPacket,
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Malformed sensor measurement packet discarded"
            )

        case .invalidServiceState, .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "SENSOR-UNEXPECTED-001"),
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Unexpected sensor service error"
            )
        }
    }
}

struct AppFailureMapper: FailureClassifying {
    typealias Failure = AppFailure

    func classify(failure: AppFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .dependencyConstructionFailed:
            return FailureClassification(
                id: .appDependencyConstructionFailed,
                severity: .critical,
                impact: .blocksAppLaunch,
                recoverability: .fatalForApplication,
                suggestedActions: [.contactSupport],
                diagnosticMessage: "App dependency graph construction failed"
            )

        case .routeStorageUnavailable, .routeMigrationFailed:
            return FailureClassification(
                id: .appStorageUnavailable,
                severity: .high,
                impact: .blocksRouteImport,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "App route storage initialization or migration failed"
            )

        case .invalidConfiguration:
            return FailureClassification(
                id: FailureID(rawValue: "APP-CONFIG-001"),
                severity: .high,
                impact: .blocksRidePreparation,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.contactSupport],
                diagnosticMessage: "Invalid app configuration detected"
            )

        case .essentialServiceUnavailable:
            return FailureClassification(
                id: FailureID(rawValue: "APP-ESSENTIAL-001"),
                severity: .critical,
                impact: .blocksAppLaunch,
                recoverability: .fatalForApplication,
                suggestedActions: [.contactSupport],
                diagnosticMessage: "Essential system service is unavailable"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "APP-UNEXPECTED-001"),
                severity: .high,
                impact: .none,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "Unexpected application startup error"
            )
        }
    }
}
