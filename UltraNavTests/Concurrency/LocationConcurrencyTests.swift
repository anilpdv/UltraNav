import Foundation
import Testing
@testable import UltraNav

@Suite("LocationConcurrency Tests")
struct LocationConcurrencyTests {
    @Test("Location mock stream produces events across task boundaries")
    func testLocationMockEvents() async {
        let fake = FakeLocationProvider()
        let received = LockedValue<[LocationServiceEvent]>([])

        let task = Task {
            for await event in fake.events {
                received.withLock { $0.append(event) }
            }
        }

        fake.send(.updateStarted)
        fake.send(.locationReceived(LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.03),
            altitudeMeters: 50,
            horizontalAccuracyMeters: 5,
            verticalAccuracyMeters: 5,
            speedMetersPerSecond: 6.5,
            courseDegrees: 90,
            timestamp: Date()
        )))

        try? await Task.sleep(nanoseconds: 30_000_000)
        fake.finishEvents()
        task.cancel()

        #expect(received.get().count >= 1)
    }
}
