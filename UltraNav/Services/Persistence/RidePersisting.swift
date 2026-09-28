import Foundation

protocol RidePersisting: Sendable {
    func save(
        _ ride: CompletedRide
    ) async throws

    func loadRide(
        id: CompletedRide.ID
    ) async throws -> CompletedRide

    func listRides() async throws
        -> [CompletedRide]

    func deleteRide(
        id: CompletedRide.ID
    ) async throws
}
