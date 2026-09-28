import CoreLocation
import XCTest
@testable import UltraNav

@MainActor
final class LocationServiceTests: XCTestCase {
    private var manager: FakeLocationManager!
    private var bridge: CoreLocationDelegateBridge!
    private var converter: CoreLocationSampleConverter!
    private var service: LocationService!

    override func setUp() {
        super.setUp()
        manager = FakeLocationManager()
        bridge = CoreLocationDelegateBridge()
        converter = CoreLocationSampleConverter()
        service = LocationService(
            manager: manager,
            delegateBridge: bridge,
            converter: converter,
            configuration: .cycling
        )
    }

    func testManagerConfiguration() {
        XCTAssertEqual(manager.desiredAccuracy, 10)
        XCTAssertEqual(manager.distanceFilter, 2)
        XCTAssertEqual(manager.activityType, .fitness)
    }

    func testRequestAuthorizationWhenNotDeterminedRequestsAuthorization() async {
        manager.authorizationStatus = .notDetermined
        await service.requestAuthorization()
        XCTAssertEqual(manager.authorizationRequestCount, 1)
    }

    func testRequestAuthorizationWhenAlreadyAuthorizedDoesNotRequestAgain() async {
        manager.authorizationStatus = .authorizedWhenInUse
        await service.requestAuthorization()
        XCTAssertEqual(manager.authorizationRequestCount, 0)
    }

    func testStartUpdatesWhenAuthorizedStartsManagerAndEmitsEvent() async throws {
        manager.authorizationStatus = .authorizedWhenInUse

        let exp = expectation(description: "updateStarted emitted")
        let task = Task {
            for await event in service.events {
                if event == .updateStarted {
                    exp.fulfill()
                    break
                }
            }
        }

        try await service.startUpdates()
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(manager.startUpdatingCallCount, 1)
        task.cancel()
    }

    func testStartUpdatesWhenDeniedThrowsError() async {
        manager.authorizationStatus = .denied

        do {
            try await service.startUpdates()
            XCTFail("Expected startUpdates to throw")
        } catch {
            XCTAssertEqual(error as? LocationServiceFailure, .authorizationDenied)
        }
        XCTAssertEqual(manager.startUpdatingCallCount, 0)
    }

    func testStartUpdatesWhenRestrictedThrowsError() async {
        manager.authorizationStatus = .restricted

        do {
            try await service.startUpdates()
            XCTFail("Expected startUpdates to throw")
        } catch {
            XCTAssertEqual(error as? LocationServiceFailure, .authorizationRestricted)
        }
        XCTAssertEqual(manager.startUpdatingCallCount, 0)
    }

    func testStartUpdatesWhenNotDeterminedThrowsError() async {
        manager.authorizationStatus = .notDetermined

        do {
            try await service.startUpdates()
            XCTFail("Expected startUpdates to throw")
        } catch {
            XCTAssertEqual(error as? LocationServiceFailure, .updatesUnavailable)
        }
        XCTAssertEqual(manager.startUpdatingCallCount, 0)
    }

    func testDuplicateStartIsIdempotent() async throws {
        manager.authorizationStatus = .authorizedWhenInUse

        try await service.startUpdates()
        try await service.startUpdates()

        XCTAssertEqual(manager.startUpdatingCallCount, 1)
    }

    func testStopUpdatesStopsManagerAndEmitsEvent() async throws {
        manager.authorizationStatus = .authorizedWhenInUse
        try await service.startUpdates()

        let exp = expectation(description: "updateStopped emitted")
        let task = Task {
            for await event in service.events {
                if event == .updateStopped {
                    exp.fulfill()
                    break
                }
            }
        }

        await service.stopUpdates()
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(manager.stopUpdatingCallCount, 1)
        task.cancel()
    }

    func testStopUpdatesFromIdleIsSafe() async {
        await service.stopUpdates()
        XCTAssertEqual(manager.stopUpdatingCallCount, 0)
    }

    func testLocationsReceivedWhileRunningEmitsLocationSample() async throws {
        manager.authorizationStatus = .authorizedWhenInUse
        try await service.startUpdates()

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let rawLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 15,
            horizontalAccuracy: 4,
            verticalAccuracy: 3,
            course: 180,
            speed: 10,
            timestamp: date
        )

        let exp = expectation(description: "locationReceived emitted")
        let task = Task {
            for await event in service.events {
                if case .locationReceived(let sample) = event {
                    XCTAssertEqual(sample.coordinate.latitude, 37.7749, accuracy: 0.0001)
                    XCTAssertEqual(sample.coordinate.longitude, -122.4194, accuracy: 0.0001)
                    XCTAssertEqual(sample.speedMetersPerSecond, 10)
                    exp.fulfill()
                    break
                }
            }
        }

        service.locationsReceived([rawLoc])
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testLocationsReceivedWhileIdleAreIgnored() async throws {
        let rawLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 15,
            horizontalAccuracy: 4,
            verticalAccuracy: 3,
            course: 180,
            speed: 10,
            timestamp: Date()
        )

        var receivedEvent = false
        let task = Task {
            for await event in service.events {
                if case .locationReceived = event {
                    receivedEvent = true
                }
            }
        }

        service.locationsReceived([rawLoc])
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(receivedEvent)
        task.cancel()
    }

    func testAuthorizationRevocationWhileRunningEmitsFailureAndStopsManager() async throws {
        manager.authorizationStatus = .authorizedWhenInUse
        try await service.startUpdates()

        let exp = expectation(description: "failure emitted on revocation")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event {
                    XCTAssertEqual(failure, .authorizationDenied)
                    exp.fulfill()
                    break
                }
            }
        }

        service.locationAuthorizationChanged(.denied)
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(manager.stopUpdatingCallCount, 1)
        task.cancel()
    }

    func testLocationErrorLocationUnknownEmitsUpdatesUnavailableWithoutStoppingManager() async throws {
        manager.authorizationStatus = .authorizedWhenInUse
        try await service.startUpdates()

        let exp = expectation(description: "failure emitted on unknown error")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event {
                    XCTAssertEqual(failure, .updatesUnavailable)
                    exp.fulfill()
                    break
                }
            }
        }

        let error = CLError(.locationUnknown)
        service.locationUpdateFailed(error)
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(manager.stopUpdatingCallCount, 0)
        task.cancel()
    }
}
