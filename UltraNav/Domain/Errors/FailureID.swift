import Foundation

struct FailureID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FailureID {
    // Location
    static let locationPermissionDenied = FailureID(rawValue: "LOCATION-AUTH-001")
    static let locationServiceDisabled = FailureID(rawValue: "LOCATION-DISABLED-001")
    static let locationTemporarilyUnknown = FailureID(rawValue: "LOCATION-UNKNOWN-001")
    static let locationUpdateFailed = FailureID(rawValue: "LOCATION-UPDATE-001")

    // Workout
    static let workoutAuthorizationDenied = FailureID(rawValue: "WORKOUT-AUTH-001")
    static let workoutPreparationFailed = FailureID(rawValue: "WORKOUT-PREP-001")
    static let workoutStartFailed = FailureID(rawValue: "WORKOUT-START-001")
    static let workoutPauseFailed = FailureID(rawValue: "WORKOUT-PAUSE-001")
    static let workoutResumeFailed = FailureID(rawValue: "WORKOUT-RESUME-001")
    static let workoutFinishFailed = FailureID(rawValue: "WORKOUT-FINISH-001")
    static let workoutSessionTerminated = FailureID(rawValue: "WORKOUT-TERMINATED-001")
    static let workoutSaveFailed = FailureID(rawValue: "WORKOUT-SAVE-001")

    // Sensors
    static let bluetoothUnavailable = FailureID(rawValue: "SENSOR-BT-001")
    static let sensorScanFailed = FailureID(rawValue: "SENSOR-SCAN-001")
    static let sensorConnectionFailed = FailureID(rawValue: "SENSOR-CONNECT-001")
    static let sensorDisconnected = FailureID(rawValue: "SENSOR-DISCONNECT-001")
    static let sensorMalformedPacket = FailureID(rawValue: "SENSOR-PACKET-001")

    // Navigation
    static let navigationRouteMissing = FailureID(rawValue: "NAV-ROUTE-001")
    static let navigationMatcherFailed = FailureID(rawValue: "NAV-MATCH-001")
    static let navigationOffRoute = FailureID(rawValue: "NAV-OFFROUTE-001")

    // Routes
    static let routeFileNotFound = FailureID(rawValue: "ROUTE-NOTFOUND-001")
    static let routeMalformedGPX = FailureID(rawValue: "ROUTE-PARSE-001")
    static let routeValidationFailed = FailureID(rawValue: "ROUTE-VALIDATION-001")
    static let routeStoreWriteFailed = FailureID(rawValue: "ROUTE-STORE-001")
    static let routeDuplicate = FailureID(rawValue: "ROUTE-DUPLICATE-001")

    // Metrics
    static let metricObservationInvalid = FailureID(rawValue: "METRIC-OBS-001")
    static let metricSourceStale = FailureID(rawValue: "METRIC-STALE-001")
    static let metricAggregationFailed = FailureID(rawValue: "METRIC-AGGR-001")

    // Climb
    static let climbAnalysisFailed = FailureID(rawValue: "CLIMB-ANALYSIS-001")
    static let climbProgressFailed = FailureID(rawValue: "CLIMB-PROGRESS-001")

    // App Startup
    static let appDependencyConstructionFailed = FailureID(rawValue: "APP-DEP-001")
    static let appStorageUnavailable = FailureID(rawValue: "APP-STORE-001")
}
