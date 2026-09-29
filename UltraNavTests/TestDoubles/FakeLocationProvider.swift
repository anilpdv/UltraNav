import Foundation
@testable import UltraNav

actor FakeLocationProvider: LocationProviding {
    nonisolated let events: AsyncStream<LocationServiceEvent>
    private let continuation: AsyncStream<LocationServiceEvent>.Continuation

    enum Call: Equatable, Sendable {
        case authorizationStatus
        case requestAuthorization
        case startUpdates
        case stopUpdates
    }

    private(set) var calls: [Call] = []
    private(set) var requestAuthorizationCallCount = 0
    private(set) var startUpdatesCallCount = 0
    private(set) var stopUpdatesCallCount = 0

    var stubbedAuthorizationStatus: LocationAuthorizationStatus = .notDetermined
    var startUpdatesFailure: LocationServiceFailure?
    var startGate: OperationGate?

    init() {
        let pair = AsyncStream.makeStream(of: LocationServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    func setStubbedAuthorizationStatus(_ status: LocationAuthorizationStatus) {
        self.stubbedAuthorizationStatus = status
    }

    func setStartUpdatesFailure(_ failure: LocationServiceFailure?) {
        self.startUpdatesFailure = failure
    }

    func setStartFailure(_ failure: LocationServiceFailure?) {
        self.startUpdatesFailure = failure
    }

    func setStartGate(_ gate: OperationGate?) {
        self.startGate = gate
    }

    func authorizationStatus() async -> LocationAuthorizationStatus {
        calls.append(.authorizationStatus)
        return stubbedAuthorizationStatus
    }

    func requestAuthorization() async {
        calls.append(.requestAuthorization)
        requestAuthorizationCallCount += 1
    }

    func startUpdates() async throws {
        calls.append(.startUpdates)
        startUpdatesCallCount += 1

        if let gate = startGate {
            try await gate.wait()
        }

        if let startUpdatesFailure {
            throw startUpdatesFailure
        }
    }

    func stopUpdates() async {
        calls.append(.stopUpdates)
        stopUpdatesCallCount += 1
    }

    nonisolated func send(_ event: LocationServiceEvent) {
        continuation.yield(event)
    }

    nonisolated func finishEvents() {
        continuation.finish()
    }

    func clear() {
        calls.removeAll()
        requestAuthorizationCallCount = 0
        startUpdatesCallCount = 0
        stopUpdatesCallCount = 0
        startUpdatesFailure = nil
        startGate = nil
    }
}
