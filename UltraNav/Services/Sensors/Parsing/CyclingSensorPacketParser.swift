import Foundation

actor CyclingSensorPacketParser: SensorPacketParsing {
    private let hrParser: LegacyHeartRateParserAdapter
    private let powerParser: LegacyCyclingPowerParserAdapter
    private let cscParser: LegacyCSCParserAdapter

    init(
        hrParser: LegacyHeartRateParserAdapter = LegacyHeartRateParserAdapter(),
        powerParser: LegacyCyclingPowerParserAdapter = LegacyCyclingPowerParserAdapter(),
        cscParser: LegacyCSCParserAdapter = LegacyCSCParserAdapter()
    ) {
        self.hrParser = hrParser
        self.powerParser = powerParser
        self.cscParser = cscParser
    }

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        let charID = packet.characteristicIdentifier.uppercased()
        switch charID {
        case "2A37":
            return try await hrParser.parse(packet)
        case "2A63":
            return try await powerParser.parse(packet)
        case "2A5B":
            return try await cscParser.parse(packet)
        default:
            return []
        }
    }
}
