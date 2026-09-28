import Foundation

protocol SensorProviding: Sendable {
    var events: AsyncStream<SensorServiceEvent> { get }

    func isAvailable() async -> Bool

    func knownSensors() async -> [SensorDescriptor]

    func startScanning(
        for types: Set<SensorType>
    ) async throws

    func stopScanning() async

    func connect(
        to sensor: SensorIdentifier
    ) async throws

    func disconnect(
        from sensor: SensorIdentifier
    ) async

    func disconnectAll() async
}
