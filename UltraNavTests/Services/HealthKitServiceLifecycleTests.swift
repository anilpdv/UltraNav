import Foundation
import HealthKit
import XCTest
@testable import UltraNav

@MainActor
final class HealthKitServiceLifecycleTests: XCTestCase {
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

    func testPrepareTransitionsToReadyAndCallsSessionPrepare() async throws {
        try await service.prepare()

        XCTAssertEqual(factory.session.prepareCallCount, 1)
        XCTAssertEqual(service.state, .ready)
    }

    func testStartBeginsBuilderCollectionAndStartsSessionActivity() async throws {
        try await service.prepare()

        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        try await service.start(at: startDate)

        XCTAssertEqual(factory.builder.beginDates.first, startDate)
        XCTAssertEqual(factory.session.startDates.first, startDate)
        XCTAssertEqual(service.state, .running)
    }

    func testPauseAndResumeLifecycle() async throws {
        try await service.prepare()
        try await service.start(at: Date())

        try await service.pause()
        XCTAssertEqual(factory.session.pauseCallCount, 1)
        XCTAssertEqual(service.state, .paused)

        try await service.resume()
        XCTAssertEqual(factory.session.resumeCallCount, 1)
        XCTAssertEqual(service.state, .running)
    }

    func testFinishLifecycleEndsSessionAndEmitsWorkoutSaved() async throws {
        try await service.prepare()
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        try await service.start(at: startDate)

        let endDate = Date(timeIntervalSince1970: 1_700_003_600)

        let exp = expectation(description: "workoutSaved emitted")
        let task = Task {
            for await event in service.events {
                if case .workoutSaved(let ref) = event {
                    XCTAssertEqual(ref.startDate, startDate)
                    exp.fulfill()
                    break
                }
            }
        }

        try await service.finish(at: endDate)
        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(factory.session.stopDates.first, endDate)
        XCTAssertEqual(factory.builder.endDates.first, endDate)
        XCTAssertEqual(factory.builder.finishCallCount, 1)
        XCTAssertEqual(factory.session.endCallCount, 1)
        XCTAssertEqual(service.state, .ended)

        task.cancel()
    }

    func testResetReturnsStateToIdle() async throws {
        try await service.prepare()
        try await service.start(at: Date())
        try await service.finish(at: Date())

        await service.reset()
        XCTAssertEqual(service.state, .idle)
    }
}
