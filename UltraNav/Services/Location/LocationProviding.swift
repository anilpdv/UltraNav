import Foundation

protocol LocationProviding: Sendable {
    var events: AsyncStream<LocationServiceEvent> { get }

    func authorizationStatus() async
        -> LocationAuthorizationStatus

    func requestAuthorization() async

    func startUpdates() async throws

    func stopUpdates() async
}
