import Foundation

enum GaugeMetric: String, CaseIterable, Equatable, Hashable, Sendable {
    case connectedSensorCount
    case readySensorCount
    case routePointCount
    case detectedClimbCount
    case activeFailureCount
    case activeDegradationCount

    case locationStreamBufferDrops
    case sensorStreamBufferDrops

    case routeImportDurationMilliseconds
    case climbAnalysisDurationMilliseconds
}
