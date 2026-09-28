import Foundation

// TODO(PHASE-8): Replace legacy parser after byte-level protocol audit.
actor LegacyCyclingPowerParserAdapter: SensorPacketParsing {
    private var lastCrankRevolutions: UInt16?
    private var lastCrankEventTime: UInt16?

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        guard packet.characteristicIdentifier.caseInsensitiveCompare("2A63") == .orderedSame else {
            return []
        }
        let data = packet.payload
        guard !data.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }
        guard data.count >= 4 else {
            throw SensorPacketParsingFailure.insufficientBytes
        }

        var samples: [SensorSample] = []

        // Bytes 0-1: Flags, Bytes 2-3: Instantaneous Power (sint16)
        let rawPower = Int16(data[2]) | (Int16(data[3]) << 8)
        let watts = max(0, Int(rawPower))
        samples.append(.power(watts: watts, timestamp: packet.receivedAt))

        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        // Bit 5 = Crank Revolution Data Present
        if (flags & 0x0020) != 0 && data.count >= 8 {
            var offset = 4
            if (flags & 0x0001) != 0 { offset += 1 } // Pedal Power Balance
            if (flags & 0x0004) != 0 { offset += 2 } // Accumulated Torque
            if (flags & 0x0010) != 0 { offset += 6 } // Wheel Revolution Data

            if data.count >= offset + 4 {
                let crankRev = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
                let crankTime = UInt16(data[offset + 2]) | (UInt16(data[offset + 3]) << 8)
                if let cadence = calculateCadence(crankRev: crankRev, crankTime: crankTime) {
                    samples.append(.cadence(revolutionsPerMinute: cadence, timestamp: packet.receivedAt))
                }
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
}
