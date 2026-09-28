import Foundation

enum SensorType: String, CaseIterable, Equatable, Hashable, Sendable {
    case heartRate
    case cyclingPower
    case cyclingSpeed
    case cyclingCadence
    case combinedSpeedCadence
}
