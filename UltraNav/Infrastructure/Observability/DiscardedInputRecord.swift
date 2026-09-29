import Foundation

enum DiscardReason: String, CaseIterable, Equatable, Hashable, Sendable {
    case invalidCoordinate
    case invalidAccuracy
    case invalidMeasurement
    case staleTimestamp
    case outOfOrder
    case malformedPacket
    case unsupportedCharacteristic
    case unsupportedGPXElement
    case cancelled
    case superseded
}

struct DiscardedInputRecord: Equatable, Sendable {
    let subsystem: ObservedSubsystem
    let reason: DiscardReason
    let source: String?
    let count: Int

    init(
        subsystem: ObservedSubsystem,
        reason: DiscardReason,
        source: String? = nil,
        count: Int = 1
    ) {
        self.subsystem = subsystem
        self.reason = reason
        self.source = source
        self.count = count
    }
}
