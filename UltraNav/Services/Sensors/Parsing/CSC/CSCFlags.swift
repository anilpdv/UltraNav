import Foundation

/// Flags representing fields present in a Bluetooth Cycling Speed and Cadence (CSC) Measurement packet (0x2A5B).
struct CSCFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let wheelRevolutionDataPresent = CSCFlags(rawValue: 1 << 0)
    static let crankRevolutionDataPresent = CSCFlags(rawValue: 1 << 1)

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
