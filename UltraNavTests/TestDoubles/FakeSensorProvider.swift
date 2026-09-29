import Foundation
@testable import UltraNav

actor FakeSensorProvider: SensorProviding {
    nonisolated let events: AsyncStream<SensorServiceEvent>
    private let continuation: AsyncStream<SensorServiceEvent>.Continuation

    enum Call: Equatable, Sendable {
        case isAvailable
        case knownSensors
        case startScanning(SensorScanRequest)
        case stopScanning
        case connect(SensorIdentifier)
        case disconnect(SensorIdentifier)
        case disconnectAll
    }

    private(set) var calls: [Call] = []

    var stubbedIsAvailable: Bool = true
    var stubbedKnownSensors: [SensorDescriptor] = []
    var scanFailure: SensorServiceFailure?
    var connectionFailures: [SensorIdentifier: SensorServiceFailure] = [:]
    var connectGate: OperationGate?

    private(set) var startScanningCallCount = 0
    private(set) var scannedTypes: Set<SensorType> = []
    private(set) var lastScanRequest: SensorScanRequest?
    private(set) var stopScanningCallCount = 0
    private(set) var connectedSensors: [SensorIdentifier] = []
    private(set) var disconnectedSensors: [SensorIdentifier] = []
    private(set) var disconnectAllCallCount = 0

    init() {
        let pair = AsyncStream.makeStream(of: SensorServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    func setStubbedIsAvailable(_ available: Bool) {
        self.stubbedIsAvailable = available
    }

    func setStubbedKnownSensors(_ sensors: [SensorDescriptor]) {
        self.stubbedKnownSensors = sensors
    }

    func setScanFailure(_ failure: SensorServiceFailure?) {
        self.scanFailure = failure
    }

    func setConnectionFailure(_ failure: SensorServiceFailure?, for sensor: SensorIdentifier) {
        if let failure {
            self.connectionFailures[sensor] = failure
        } else {
            self.connectionFailures.removeValue(forKey: sensor)
        }
    }

    func setConnectGate(_ gate: OperationGate?) {
        self.connectGate = gate
    }

    func isAvailable() async -> Bool {
        calls.append(.isAvailable)
        return stubbedIsAvailable
    }

    func knownSensors() async -> [SensorDescriptor] {
        calls.append(.knownSensors)
        return stubbedKnownSensors
    }

    func startScanning(request: SensorScanRequest) async throws {
        calls.append(.startScanning(request))
        startScanningCallCount += 1
        scannedTypes = request.sensorTypes
        lastScanRequest = request

        if let scanFailure {
            throw scanFailure
        }
    }

    func startScanning(for types: Set<SensorType>) async throws {
        try await startScanning(request: .standard(for: types))
    }

    func stopScanning() async {
        calls.append(.stopScanning)
        stopScanningCallCount += 1
    }

    func connect(to sensor: SensorIdentifier) async throws {
        calls.append(.connect(sensor))

        if let gate = connectGate {
            try await gate.wait()
        }

        if let failure = connectionFailures[sensor] {
            throw failure
        }
        connectedSensors.append(sensor)
    }

    func disconnect(from sensor: SensorIdentifier) async {
        calls.append(.disconnect(sensor))
        disconnectedSensors.append(sensor)
    }

    func disconnectAll() async {
        calls.append(.disconnectAll)
        disconnectAllCallCount += 1
    }

    nonisolated func send(_ event: SensorServiceEvent) {
        continuation.yield(event)
    }

    nonisolated func finishEvents() {
        continuation.finish()
    }

    func clear() {
        calls.removeAll()
        startScanningCallCount = 0
        scannedTypes.removeAll()
        lastScanRequest = nil
        stopScanningCallCount = 0
        connectedSensors.removeAll()
        disconnectedSensors.removeAll()
        disconnectAllCallCount = 0
        connectionFailures.removeAll()
        connectGate = nil
    }
}
