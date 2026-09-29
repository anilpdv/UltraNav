import Foundation

/// Flags representing the fields present in a Bluetooth Heart Rate Measurement characteristic packet (0x2A37).
struct HeartRateFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let is16BitHeartRateValue    = HeartRateFlags(rawValue: 1 << 0)
    static let sensorContactDetected    = HeartRateFlags(rawValue: 1 << 1)
    static let sensorContactSupported   = HeartRateFlags(rawValue: 1 << 2)
    static let energyExpendedPresent    = HeartRateFlags(rawValue: 1 << 3)
    static let rrIntervalPresent        = HeartRateFlags(rawValue: 1 << 4)

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
