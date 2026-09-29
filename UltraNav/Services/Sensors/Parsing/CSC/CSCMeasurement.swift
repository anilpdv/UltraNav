import Foundation

/// Parsed typed representation of a Bluetooth CSC Measurement.
struct CSCMeasurement: Equatable, Sendable {
    let cumulativeWheelRevolutions: UInt32?
    let lastWheelEventTime: UInt16?
    let cumulativeCrankRevolutions: UInt16?
    let lastCrankEventTime: UInt16?

    init(
        cumulativeWheelRevolutions: UInt32? = nil,
        lastWheelEventTime: UInt16? = nil,
        cumulativeCrankRevolutions: UInt16? = nil,
        lastCrankEventTime: UInt16? = nil
    ) {
        self.cumulativeWheelRevolutions = cumulativeWheelRevolutions
        self.lastWheelEventTime = lastWheelEventTime
        self.cumulativeCrankRevolutions = cumulativeCrankRevolutions
        self.lastCrankEventTime = lastCrankEventTime
    }
}
