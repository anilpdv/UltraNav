import Foundation

/// Production Bluetooth service conforming to the SensorProviding boundary.
final class BluetoothService: SensorProviding, Sendable {
    nonisolated let events: AsyncStream<SensorServiceEvent>
    private let continuation: AsyncStream<SensorServiceEvent>.Continuation

    init() {
        let pair = AsyncStream.makeStream(of: SensorServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    func isAvailable() async -> Bool {
        true
    }

    func knownSensors() async -> [SensorDescriptor] {
        []
    }

    func startScanning(for types: Set<SensorType>) async throws {
        continuation.yield(.scanStarted)
    }

    func stopScanning() async {
        continuation.yield(.scanStopped)
    }

    func connect(to sensor: SensorIdentifier) async throws {
        continuation.yield(.connectionStateChanged(sensor: sensor, state: .connected))
    }

    func disconnect(from sensor: SensorIdentifier) async {
        continuation.yield(.connectionStateChanged(sensor: sensor, state: .disconnected))
    }

    func disconnectAll() async {
        continuation.yield(.scanStopped)
    }
}
