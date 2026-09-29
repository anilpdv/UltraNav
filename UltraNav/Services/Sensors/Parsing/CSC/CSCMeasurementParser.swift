import Foundation

/// Strict, spec-compliant parser for Bluetooth Cycling Speed and Cadence (CSC) Measurement packets (0x2A5B).
actor CSCMeasurementParser {
    private var revolutionState = CSCRevolutionState()

    init() {}

    func parse(payload: Data, receivedAt: Date = Date()) throws -> (CSCMeasurement, [SensorSample]) {
        guard !payload.isEmpty else {
            throw SensorPacketParsingFailure.emptyPayload
        }

        var cursor = SensorPacketCursor(data: payload)
        let rawFlags = try cursor.readUInt8()
        let flags = CSCFlags(rawValue: rawFlags)

        var wheelRevs: UInt32? = nil
        var wheelTime: UInt16? = nil
        var crankRevs: UInt16? = nil
        var crankTime: UInt16? = nil

        if flags.contains(.wheelRevolutionDataPresent) {
            wheelRevs = try cursor.readUInt32LE()
            wheelTime = try cursor.readUInt16LE()
        }

        if flags.contains(.crankRevolutionDataPresent) {
            crankRevs = try cursor.readUInt16LE()
            crankTime = try cursor.readUInt16LE()
        }

        let measurement = CSCMeasurement(
            cumulativeWheelRevolutions: wheelRevs,
            lastWheelEventTime: wheelTime,
            cumulativeCrankRevolutions: crankRevs,
            lastCrankEventTime: crankTime
        )

        var samples: [SensorSample] = []

        if let wRev = wheelRevs, let wTime = wheelTime {
            if let speedMps = revolutionState.calculateSpeed(wheelRevolutions: wRev, wheelEventTime: wTime) {
                samples.append(.speed(metersPerSecond: speedMps, timestamp: receivedAt))
            }
        }

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
