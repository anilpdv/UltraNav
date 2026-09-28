import XCTest
@testable import UltraNav

final class FakeRidePersistenceTests: XCTestCase {
    func testSaveLoadAndListRides() async throws {
        let store = FakeRidePersistence()
        let rideId = UUID()
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let endDate = Date(timeIntervalSince1970: 1_700_003_600)

        let ride = CompletedRide(
            id: rideId,
            startedAt: startDate,
            endedAt: endDate,
            elapsedTimeSeconds: 3600,
            movingTimeSeconds: 3400,
            distanceMeters: 30000,
            averageSpeedMetersPerSecond: 8.82,
            averageHeartRateBeatsPerMinute: 145,
            averageCadenceRevolutionsPerMinute: 88,
            averagePowerWatts: 210,
            routeID: nil
        )

        try await store.save(ride)

        let loaded = try await store.loadRide(id: rideId)
        XCTAssertEqual(loaded, ride)

        let list = try await store.listRides()
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list.first?.id, rideId)

        try await store.deleteRide(id: rideId)
        let listAfterDelete = try await store.listRides()
        XCTAssertTrue(listAfterDelete.isEmpty)
    }

    func testLoadMissingRideThrows() async {
        let store = FakeRidePersistence()
        let missingId = UUID()

        do {
            _ = try await store.loadRide(id: missingId)
            XCTFail("Expected loadRide to throw")
        } catch {
            XCTAssertEqual(error as? RidePersistenceError, .rideNotFound)
        }

        do {
            try await store.deleteRide(id: missingId)
            XCTFail("Expected deleteRide to throw")
        } catch {
            XCTAssertEqual(error as? RidePersistenceError, .rideNotFound)
        }
    }
}
