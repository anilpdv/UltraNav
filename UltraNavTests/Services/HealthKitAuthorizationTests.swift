import Foundation
import HealthKit
import XCTest
@testable import UltraNav

@MainActor
final class HealthKitAuthorizationTests: XCTestCase {
    func testAuthorizationStatusWhenUnavailableReturnsUnavailable() async {
        let store = FakeHealthStore()
        await store.setAvailable(false)
        let service = HealthKitService(authorizationClient: store)

        let status = await service.authorizationStatus()
        XCTAssertEqual(status, .unavailable)
    }

    func testAuthorizationStatusWhenUnnecessaryReturnsAuthorized() async {
        let store = FakeHealthStore()
        let service = HealthKitService(authorizationClient: store)

        let status = await service.authorizationStatus()
        XCTAssertEqual(status, .authorized)
    }

    func testRequestAuthorizationSuccessEmitsAuthorizedEvent() async throws {
        let store = FakeHealthStore()
        let service = HealthKitService(authorizationClient: store)

        let exp = expectation(description: "authorizationChanged emitted")
        let task = Task {
            for await event in service.events {
                if case .authorizationChanged(let status) = event {
                    XCTAssertEqual(status, .authorized)
                    exp.fulfill()
                    break
                }
            }
        }

        try await service.requestAuthorization()
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testRequestAuthorizationFailureThrowsAndEmitsFailure() async {
        let store = FakeHealthStore()
        await store.setShouldFailRequest(true)
        let service = HealthKitService(authorizationClient: store)

        do {
            try await service.requestAuthorization()
            XCTFail("Expected requestAuthorization to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .authorizationFailed)
        }
    }
}
