import Foundation

/// Production sensor measurement parser delegating to SensorPacketProcessor.
actor CyclingSensorPacketParser: SensorPacketParsing {
    private let processor: SensorPacketProcessor

    init(processor: SensorPacketProcessor = SensorPacketProcessor()) {
        self.processor = processor
    }

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        try await processor.parse(packet)
    }

    func reset(sensor: SensorIdentifier) async {
        await processor.reset(sensor: sensor)
    }

    func resetAll() async {
        await processor.resetAll()
    }
}
