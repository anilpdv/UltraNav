import Foundation

enum CounterMetric: String, CaseIterable, Equatable, Hashable, Sendable {
    case locationSamplesReceived
    case locationSamplesDiscarded

    case workoutMetricsReceived

    case sensorPacketsReceived
    case sensorPacketsMalformed

    case routeImportsStarted
    case routeImportsSucceeded
    case routeImportsFailed

    case navigationMatchesSucceeded
    case navigationMatchesUnavailable
    case navigationCalculationsFailed

    case snapshotsPublished

    case streamEventsDropped

    case recoveryAttempts
    case recoverySuccesses
    case recoveryFailures
}
