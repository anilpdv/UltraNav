import Foundation
@testable import UltraNav

actor FakeSensorPacketParser: SensorPacketParsing {
    private(set) var receivedPackets: [SensorMeasurementPacket] = []
    var result: [SensorSample] = []
    var failure: SensorPacketParsingFailure?

    func setStubbedResult(_ result: [SensorSample]) {
        self.result = result
    }

    func setFailure(_ failure: SensorPacketParsingFailure?) {
        self.failure = failure
    }

    func parse(_ packet: SensorMeasurementPacket) async throws -> [SensorSample] {
        receivedPackets.append(packet)
        if let failure {
            throw failure
        }
        return result
    }
}
