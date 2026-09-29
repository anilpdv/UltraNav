import Foundation

/// Strict, spec-compliant parser for Bluetooth Cycling Power Measurement packets (0x2A63).
actor CyclingPowerMeasurementParser {
    private var revolutionState = CyclingPowerRevolutionState()

    init() {}

    func parse(payload: Data, receivedAt: Date = Date()) throws -> (CyclingPowerMeasurement, [SensorSample]) {
        guard !payload.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }

        var cursor = SensorPacketCursor(data: payload)
        let rawFlags = try cursor.readUInt16LE()
        let flags = CyclingPowerFlags(rawValue: rawFlags)

        let powerWatts = try cursor.readInt16LE()

        var wheelRevs: UInt32? = nil
        var wheelTime: UInt16? = nil
        var crankRevs: UInt16? = nil
        var crankTime: UInt16? = nil

        // Optional fields strictly ordered
        if flags.contains(.pedalPowerBalancePresent) {
            try cursor.skip(bytes: 1)
        }
        if flags.contains(.accumulatedTorquePresent) {
            try cursor.skip(bytes: 2)
        }
        if flags.contains(.wheelRevolutionDataPresent) {
            wheelRevs = try cursor.readUInt32LE()
            wheelTime = try cursor.readUInt16LE()
        }
        if flags.contains(.crankRevolutionDataPresent) {
            crankRevs = try cursor.readUInt16LE()
            crankTime = try cursor.readUInt16LE()
        }

        let measurement = CyclingPowerMeasurement(
            instantaneousPowerWatts: powerWatts,
            cumulativeWheelRevolutions: wheelRevs,
            lastWheelEventTime: wheelTime,
            cumulativeCrankRevolutions: crankRevs,
            lastCrankEventTime: crankTime
        )

        var samples: [SensorSample] = [
            .power(watts: max(0, Int(powerWatts)), timestamp: receivedAt)
        ]

        if let cRev = crankRevs, let cTime = crankTime {
            if let cadenceRpm = revolutionState.calculateCadence(crankRevolutions: cRev, crankEventTime: cTime) {
                samples.append(.cadence(revolutionsPerMinute: cadenceRpm, timestamp: receivedAt))
            }
        }

        return (measurement, samples)
    }

    func reset() {
        revolutionState.reset()
    }
}
