import Foundation

enum MetricValue: Hashable, Sendable {
    case speed(metersPerSecond: Double)
    case heartRate(beatsPerMinute: Int)
    case cadence(revolutionsPerMinute: Double)
    case power(watts: Int)
    case distance(meters: Double)
    case altitude(meters: Double)
    case energy(kilocalories: Double)
}
