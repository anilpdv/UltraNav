import Foundation

enum SensorSample: Equatable, Sendable {
    case heartRate(
        beatsPerMinute: Int,
        timestamp: Date
    )

    case power(
        watts: Int,
        timestamp: Date
    )

    case cadence(
        revolutionsPerMinute: Double,
        timestamp: Date
    )

    case speed(
        metersPerSecond: Double,
        timestamp: Date
    )
}
