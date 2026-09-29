import Foundation

/// Parsed typed representation of a Bluetooth Cycling Power Measurement.
struct CyclingPowerMeasurement: Equatable, Sendable {
    let instantaneousPowerWatts: Int16
    let cumulativeWheelRevolutions: UInt32?
    let lastWheelEventTime: UInt16?
    let cumulativeCrankRevolutions: UInt16?
    let lastCrankEventTime: UInt16?

    init(
        instantaneousPowerWatts: Int16,
        cumulativeWheelRevolutions: UInt32? = nil,
        lastWheelEventTime: UInt16? = nil,
        cumulativeCrankRevolutions: UInt16? = nil,
        lastCrankEventTime: UInt16? = nil
    ) {
        self.instantaneousPowerWatts = instantaneousPowerWatts
        self.cumulativeWheelRevolutions = cumulativeWheelRevolutions
        self.lastWheelEventTime = lastWheelEventTime
        self.cumulativeCrankRevolutions = cumulativeCrankRevolutions
        self.lastCrankEventTime = lastCrankEventTime
    }
}
