import Foundation

// TODO(PHASE-8): Replace legacy parser after byte-level protocol audit.
struct LegacyHeartRateParserAdapter: SensorPacketParsing {
    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        guard packet.characteristicIdentifier.caseInsensitiveCompare("2A37") == .orderedSame else {
            return []
        }
        guard !packet.payload.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }
        guard packet.payload.count >= 2 else {
            throw SensorPacketParsingFailure.insufficientBytes
        }

        let flags = packet.payload[0]
        let is16Bit = (flags & 0x01) != 0
        let hr: Int
        if is16Bit {
            guard packet.payload.count >= 3 else {
                throw SensorPacketParsingFailure.insufficientBytes
            }
            hr = Int(UInt16(packet.payload[1]) | (UInt16(packet.payload[2]) << 8))
        } else {
            hr = Int(packet.payload[1])
        }

        return [
            .heartRate(
                beatsPerMinute: hr,
                timestamp: packet.receivedAt
            )
        ]
    }
}
