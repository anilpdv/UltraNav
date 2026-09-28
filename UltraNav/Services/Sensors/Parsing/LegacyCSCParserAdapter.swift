import Foundation

// TODO(PHASE-8): Replace legacy parser after byte-level protocol audit.
actor LegacyCSCParserAdapter: SensorPacketParsing {
    private var lastWheelRevolutions: UInt32?
    private var lastWheelEventTime: UInt16?
    private var lastCrankRevolutions: UInt16?
    private var lastCrankEventTime: UInt16?

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        guard packet.characteristicIdentifier.caseInsensitiveCompare("2A5B") == .orderedSame else {
            return []
        }
        let data = packet.payload
        guard !data.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }
        guard data.count >= 1 else {
            throw SensorPacketParsingFailure.insufficientBytes
        }

        var samples: [SensorSample] = []
        let flags = data[0]
        var offset = 1

        let wheelPresent = (flags & 0x01) != 0
        let crankPresent = (flags & 0x02) != 0

        if wheelPresent && data.count >= offset + 6 {
            let wheelRev = UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) | (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24)
            let wheelTime = UInt16(data[offset + 4]) | (UInt16(data[offset + 5]) << 8)
            if let speedMps = calculateSpeed(wheelRev: wheelRev, wheelTime: wheelTime) {
                samples.append(.speed(metersPerSecond: speedMps, timestamp: packet.receivedAt))
            }
            offset += 6
        }

        if crankPresent && data.count >= offset + 4 {
            let crankRev = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
            let crankTime = UInt16(data[offset + 2]) | (UInt16(data[offset + 3]) << 8)
            if let cadence = calculateCadence(crankRev: crankRev, crankTime: crankTime) {
                samples.append(.cadence(revolutionsPerMinute: cadence, timestamp: packet.receivedAt))
            }
        }

        return samples
    }

    private func calculateCadence(crankRev: UInt16, crankTime: UInt16) -> Double? {
        defer {
            self.lastCrankRevolutions = crankRev
            self.lastCrankEventTime = crankTime
        }
        guard let lastRev = lastCrankRevolutions, let lastTime = lastCrankEventTime else {
            return nil
        }
        let dRev = crankRev >= lastRev ? (crankRev - lastRev) : (UInt16.max - lastRev + crankRev + 1)
        let dTime = crankTime >= lastTime ? (crankTime - lastTime) : (UInt16.max - lastTime + crankTime + 1)
        if dTime > 0 && dRev > 0 {
            let timeInSec = Double(dTime) / 1024.0
            let rpm = (Double(dRev) / timeInSec) * 60.0
            if rpm > 10 && rpm < 220 {
                return rpm.rounded()
            }
        }
        return nil
    }

    private func calculateSpeed(wheelRev: UInt32, wheelTime: UInt16) -> Double? {
        defer {
            self.lastWheelRevolutions = wheelRev
            self.lastWheelEventTime = wheelTime
        }
        guard let lastRev = lastWheelRevolutions, let lastTime = lastWheelEventTime else {
            return nil
        }
        let dRev = wheelRev >= lastRev ? (wheelRev - lastRev) : (UInt32.max - lastRev + wheelRev + 1)
        let dTime = wheelTime >= lastTime ? (wheelTime - lastTime) : (UInt16.max - lastTime + wheelTime + 1)
        if dTime > 0 && dRev > 0 {
            let timeInSec = Double(dTime) / 1024.0
            let circumferenceMeters = 2.105 // Standard 700x25c wheel
            let mps = (Double(dRev) * circumferenceMeters) / timeInSec
            if mps >= 0 && mps < 40 {
                return mps
            }
        }
        return nil
    }
}
