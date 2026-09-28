import Foundation

enum SensorPacketParsingFailure: Error, Equatable, Sendable {
    case emptyPayload
    case unsupportedService(String)
    case unsupportedCharacteristic(String)
    case malformedFlags
    case insufficientBytes
    case invalidMeasurement
    case unsupportedMeasurement
}

protocol SensorPacketParsing: Sendable {
    func parse(
        _ packet: SensorMeasurementPacket
    ) async throws -> [SensorSample]
}
