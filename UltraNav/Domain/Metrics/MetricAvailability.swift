import Foundation

struct MetricAvailability: Equatable, Sendable {
    let hasSpeed: Bool
    let hasHeartRate: Bool
    let hasCadence: Bool
    let hasPower: Bool
    let hasDistance: Bool
    let hasAltitude: Bool
    let hasEnergy: Bool

    init(
        hasSpeed: Bool = false,
        hasHeartRate: Bool = false,
        hasCadence: Bool = false,
        hasPower: Bool = false,
        hasDistance: Bool = false,
        hasAltitude: Bool = false,
        hasEnergy: Bool = false
    ) {
        self.hasSpeed = hasSpeed
        self.hasHeartRate = hasHeartRate
        self.hasCadence = hasCadence
        self.hasPower = hasPower
        self.hasDistance = hasDistance
        self.hasAltitude = hasAltitude
        self.hasEnergy = hasEnergy
    }

    static let empty = MetricAvailability()
}
