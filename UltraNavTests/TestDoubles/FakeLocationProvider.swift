import Foundation
@testable import UltraNav

actor FakeLocationProvider: LocationProviding {
    nonisolated let events: AsyncStream<LocationServiceEvent>

    private let continuation: AsyncStream<LocationServiceEvent>.Continuation

    private(set) var requestAuthorizationCallCount = 0
    private(set) var startUpdatesCallCount = 0
    private(set) var stopUpdatesCallCount = 0

    var stubbedAuthorizationStatus: LocationAuthorizationStatus = .notDetermined
    var startUpdatesFailure: LocationServiceFailure?

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

    func authorizationStatus() async -> LocationAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAuthorization() async {
        requestAuthorizationCallCount += 1
    }

    func startUpdates() async throws {
        startUpdatesCallCount += 1

        if let startUpdatesFailure {
            throw startUpdatesFailure
        }
    }

    func stopUpdates() async {
        stopUpdatesCallCount += 1
    }

    func send(_ event: LocationServiceEvent) {
        continuation.yield(event)
    }

    func finishEvents() {
        continuation.finish()
    }
}
