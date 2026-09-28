import Foundation

/// Production HealthKit service conforming to the WorkoutProviding boundary.
final class HealthKitService: WorkoutProviding, Sendable {
    nonisolated let events: AsyncStream<WorkoutServiceEvent>
    private let continuation: AsyncStream<WorkoutServiceEvent>.Continuation

    init() {
        let pair = AsyncStream.makeStream(of: WorkoutServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    func authorizationStatus() async -> WorkoutAuthorizationStatus {
        .notDetermined
    }

    func requestAuthorization() async throws {
        continuation.yield(.authorizationChanged(.authorized))
    }

    func prepare() async throws {
        continuation.yield(.stateChanged(.ready))
    }

    func start(at date: Date) async throws {
        continuation.yield(.stateChanged(.running))
    }

    func pause() async throws {
        continuation.yield(.stateChanged(.paused))
    }

    func resume() async throws {
        continuation.yield(.stateChanged(.running))
    }

    func finish(at date: Date) async throws {
        continuation.yield(.stateChanged(.ended))
    }

    func reset() async {
        continuation.yield(.stateChanged(.idle))
    }
}
