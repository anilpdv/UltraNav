import Foundation

/// Strict, spec-compliant parser for Bluetooth Heart Rate Measurement packets (0x2A37).
struct HeartRateMeasurementParser: Sendable {
    init() {}

    func parse(payload: Data, receivedAt: Date = Date()) throws -> (HeartRateMeasurement, [SensorSample]) {
        guard !payload.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }

        var cursor = SensorPacketCursor(data: payload)
        let rawFlags = try cursor.readUInt8()
        let flags = HeartRateFlags(rawValue: rawFlags)

        // Read HR value
        let bpm: UInt16
        if flags.contains(.is16BitHeartRateValue) {
            bpm = try cursor.readUInt16LE()
        } else {
            let u8 = try cursor.readUInt8()
            bpm = UInt16(u8)
        }

        // Contact detection
        var contactDetected: Bool? = nil
        if flags.contains(.sensorContactSupported) {
            contactDetected = flags.contains(.sensorContactDetected)
        }

        // Energy expended
        var energy: UInt16? = nil
        if flags.contains(.energyExpendedPresent) {
            energy = try cursor.readUInt16LE()
        }

        // RR intervals (1/1024 seconds resolution)
        var rrIntervals: [Double] = []
        if flags.contains(.rrIntervalPresent) {
            while cursor.remainingBytes >= 2 {
                let rawRR = try cursor.readUInt16LE()
                let seconds = Double(rawRR) / 1024.0
                rrIntervals.append(seconds)
            }
        }

        let measurement = HeartRateMeasurement(
            beatsPerMinute: bpm,
            sensorContactDetected: contactDetected,
            energyExpendedJoules: energy,
            rrIntervals: rrIntervals
        )

        let samples: [SensorSample] = [
            .heartRate(beatsPerMinute: Int(bpm), timestamp: receivedAt)
        ]

        return (measurement, samples)
    }
}
