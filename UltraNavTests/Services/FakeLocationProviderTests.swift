import XCTest
@testable import UltraNav

final class FakeLocationProviderTests: XCTestCase {
    func testLocationFakeDeliversInjectedEvent() async {
        let provider = FakeLocationProvider()

        let sample = LocationSample(
            coordinate: Coordinate(
                latitude: 24.7136,
                longitude: 46.6753
            ),
            altitudeMeters: 600,
            horizontalAccuracyMeters: 5,
            verticalAccuracyMeters: 8,
            speedMetersPerSecond: 7,
            courseDegrees: 90,
            timestamp: Date(
                timeIntervalSince1970: 1_700_000_000
            )
        )

        let received = expectation(description: "Location received")

        let task = Task {
            for await event in provider.events {
                if event == .locationReceived(sample) {
                    received.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        await provider.send(.locationReceived(sample))

        await fulfillment(of: [received], timeout: 1.0)
        task.cancel()
    }

    func testLocationFakeTracksCallCountsAndThrowsError() async throws {
        let provider = FakeLocationProvider()

        let initialStatus = await provider.authorizationStatus()
        XCTAssertEqual(initialStatus, .notDetermined)

        await provider.requestAuthorization()
        let authCalls = await provider.requestAuthorizationCallCount
        XCTAssertEqual(authCalls, 1)

        try await provider.startUpdates()
        let startCalls = await provider.startUpdatesCallCount
        XCTAssertEqual(startCalls, 1)

        await provider.stopUpdates()
        let stopCalls = await provider.stopUpdatesCallCount
        XCTAssertEqual(stopCalls, 1)

        await provider.setStartUpdatesFailure(.servicesDisabled)
        do {
            try await provider.startUpdates()
            XCTFail("Expected startUpdates to throw")
        } catch {
            XCTAssertEqual(error as? LocationServiceFailure, .servicesDisabled)
        }
    }
}
