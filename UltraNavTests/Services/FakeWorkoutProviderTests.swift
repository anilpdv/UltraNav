import XCTest
@testable import UltraNav

final class FakeWorkoutProviderTests: XCTestCase {
    func testWorkoutFakeDeliversInjectedEvent() async {
        let provider = FakeWorkoutProvider()
        let received = expectation(description: "Heart rate event received")

        let task = Task {
            for await event in provider.events {
                if case .heartRateReceived(let bpm, _) = event, bpm == 150 {
                    received.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        await provider.send(.heartRateReceived(beatsPerMinute: 150, timestamp: Date()))

        await fulfillment(of: [received], timeout: 1.0)
        task.cancel()
    }

    func testWorkoutFakeRecordsLifecycleDatesAndCalls() async throws {
        let provider = FakeWorkoutProvider()
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let finishDate = Date(timeIntervalSince1970: 1_700_003_600)

        try await provider.requestAuthorization()
        let authCount = await provider.authorizationCallCount
        XCTAssertEqual(authCount, 1)

        try await provider.prepare()
        let prepCount = await provider.prepareCallCount
        XCTAssertEqual(prepCount, 1)

        try await provider.start(at: startDate)
        let startDates = await provider.startDates
        XCTAssertEqual(startDates, [startDate])

        try await provider.pause()
        let pauseCount = await provider.pauseCallCount
        XCTAssertEqual(pauseCount, 1)

        try await provider.resume()
        let resumeCount = await provider.resumeCallCount
        XCTAssertEqual(resumeCount, 1)

        try await provider.finish(at: finishDate)
        let finishDates = await provider.finishDates
        XCTAssertEqual(finishDates, [finishDate])

        await provider.reset()
        let resetCount = await provider.resetCallCount
        XCTAssertEqual(resetCount, 1)
    }

    func testWorkoutFakeThrowsConfiguredFailures() async {
        let provider = FakeWorkoutProvider()

        await provider.setStartFailure(.startFailed)
        do {
            try await provider.start(at: Date())
            XCTFail("Expected start to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .startFailed)
        }

        await provider.setPauseFailure(.pauseFailed)
        do {
            try await provider.pause()
            XCTFail("Expected pause to throw")
        } catch {
            XCTAssertEqual(error as? WorkoutServiceFailure, .pauseFailed)
        }
    }
}
