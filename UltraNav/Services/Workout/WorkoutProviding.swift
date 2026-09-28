import Foundation

protocol WorkoutProviding: Sendable {
    var events: AsyncStream<WorkoutServiceEvent> { get }

    func authorizationStatus() async
        -> WorkoutAuthorizationStatus

    func requestAuthorization() async throws

    func prepare() async throws

    func start(
        at date: Date
    ) async throws

    func pause() async throws

    func resume() async throws

    func finish(
        at date: Date
    ) async throws

    func cancel() async

    func reset() async
}
