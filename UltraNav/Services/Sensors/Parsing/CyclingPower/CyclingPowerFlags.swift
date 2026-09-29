import Foundation

/// Flags representing fields present in a Bluetooth Cycling Power Measurement packet (0x2A63).
struct CyclingPowerFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    static let pedalPowerBalancePresent       = CyclingPowerFlags(rawValue: 1 << 0)
    static let pedalPowerBalanceReference     = CyclingPowerFlags(rawValue: 1 << 1)
    static let accumulatedTorquePresent       = CyclingPowerFlags(rawValue: 1 << 2)
    static let accumulatedTorqueSource        = CyclingPowerFlags(rawValue: 1 << 3)
    static let wheelRevolutionDataPresent     = CyclingPowerFlags(rawValue: 1 << 4)
    static let crankRevolutionDataPresent     = CyclingPowerFlags(rawValue: 1 << 5)
    static let extremeForceMagnitudesPresent  = CyclingPowerFlags(rawValue: 1 << 6)
    static let extremeTorqueMagnitudesPresent = CyclingPowerFlags(rawValue: 1 << 7)
    static let extremeAnglesPresent           = CyclingPowerFlags(rawValue: 1 << 8)
    static let topDeadCenterAnglePresent      = CyclingPowerFlags(rawValue: 1 << 9)
    static let bottomDeadCenterAnglePresent   = CyclingPowerFlags(rawValue: 1 << 10)
    static let accumulatedEnergyPresent       = CyclingPowerFlags(rawValue: 1 << 11)
    static let offsetCompensationIndicator    = CyclingPowerFlags(rawValue: 1 << 12)

    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}
