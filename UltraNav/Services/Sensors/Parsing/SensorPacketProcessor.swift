import Foundation

/// Coordinates multi-sensor GATT measurement packet parsing, maintaining stateful revolution counters per sensor.
actor SensorPacketProcessor: SensorPacketParsing {
    private let hrParser: HeartRateMeasurementParser
    private var powerParsers: [SensorIdentifier: CyclingPowerMeasurementParser] = [:]
    private var cscParsers: [SensorIdentifier: CSCMeasurementParser] = [:]

    init(hrParser: HeartRateMeasurementParser = HeartRateMeasurementParser()) {
        self.hrParser = hrParser
    }

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        let charID = packet.characteristicIdentifier.uppercased()
        switch charID {
        case "2A37":
            let (_, samples) = try hrParser.parse(payload: packet.payload, receivedAt: packet.receivedAt)
            return samples

        case "2A63":
            let parser = getOrCreatePowerParser(for: packet.sensor)
            let (_, samples) = try await parser.parse(payload: packet.payload, receivedAt: packet.receivedAt)
            return samples

        case "2A5B":
            let parser = getOrCreateCSCParser(for: packet.sensor)
            let (_, samples) = try await parser.parse(payload: packet.payload, receivedAt: packet.receivedAt)
            return samples

        default:
            return []
        }
    }

    func reset(sensor: SensorIdentifier) async {
        if let parser = powerParsers[sensor] {
            await parser.reset()
        }
        if let parser = cscParsers[sensor] {
            await parser.reset()
        }
    }

    func resetAll() async {
        for (_, parser) in powerParsers {
            await parser.reset()
        }
        for (_, parser) in cscParsers {
            await parser.reset()
        }
    }

    private func getOrCreatePowerParser(for sensor: SensorIdentifier) -> CyclingPowerMeasurementParser {
        if let existing = powerParsers[sensor] {
            return existing
        }
        let newParser = CyclingPowerMeasurementParser()
        powerParsers[sensor] = newParser
        return newParser
    }

    private func getOrCreateCSCParser(for sensor: SensorIdentifier) -> CSCMeasurementParser {
        if let existing = cscParsers[sensor] {
            return existing
        }
        let newParser = CSCMeasurementParser()
        cscParsers[sensor] = newParser
        return newParser
    }
}
