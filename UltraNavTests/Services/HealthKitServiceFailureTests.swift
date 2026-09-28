import Foundation
import HealthKit
import XCTest
@testable import UltraNav

@MainActor
final class HealthKitServiceFailureTests: XCTestCase {
    private var authStore: FakeHealthStore!
    private var factory: FakeWorkoutFactory!
    private var testClock: TestClock!
    private var service: HealthKitService!

    override func setUp() {
        super.setUp()
        authStore = FakeHealthStore()
        factory = FakeWorkoutFactory()
        testClock = TestClock()
        service = HealthKitService(
            authorizationClient: authStore,
            resourceFactory: factory,
            clock: testClock
        )
    }

    func testPrepareWithoutAuthorizationThrowsAuthorizationDenied() async {
        await authStore.setStubbedRequestStatus(.shouldRequest)

        do {
            try await service.prepare()
            XCTFail("Expected prepare to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .authorizationDenied)
            XCTAssertEqual(service.state, .failed)
        }
    }

    func testStartWithoutPreparationThrowsInvalidServiceState() async {
        do {
            try await service.start(at: Date())
            XCTFail("Expected start to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .invalidServiceState)
        }
    }

    func testPauseFromIdleThrowsInvalidServiceState() async {
        do {
            try await service.pause()
            XCTFail("Expected pause to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .invalidServiceState)
        }
    }
}
