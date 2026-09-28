import Foundation
@testable import UltraNav

actor FakeRidePersistence: RidePersisting {
    private var rides: [CompletedRide.ID: CompletedRide]

    init(rides: [CompletedRide] = []) {
        self.rides = Dictionary(
            uniqueKeysWithValues: rides.map { ($0.id, $0) }
        )
    }

    func save(_ ride: CompletedRide) async throws {
        rides[ride.id] = ride
    }

    func loadRide(id: CompletedRide.ID) async throws -> CompletedRide {
        guard let ride = rides[id] else {
            throw RidePersistenceError.rideNotFound
        }
        return ride
    }

    func listRides() async throws -> [CompletedRide] {
        Array(rides.values)
    }

    func deleteRide(id: CompletedRide.ID) async throws {
        guard rides.removeValue(forKey: id) != nil else {
            throw RidePersistenceError.rideNotFound
        }
    }
}
