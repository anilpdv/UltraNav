import XCTest
@testable import UltraNav

final class RideStateMachinePathTests: XCTestCase {
    func testCompleteRidePath() throws {
        var machine = RideStateMachine()

        try machine.handle(.prepareRequested)
        try machine.handle(.preparationSucceeded)
        try machine.handle(.startRequested)
        try machine.handle(.startSucceeded)
        try machine.handle(.pauseRequested)
        try machine.handle(.pauseSucceeded)
        try machine.handle(.resumeRequested)
        try machine.handle(.resumeSucceeded)
        try machine.handle(.finishRequested)
        try machine.handle(.finishSucceeded)

        XCTAssertEqual(machine.state, .completed)
    }

    func testInvalidRideTransitionsPreserveState() {
        assertRejected(
            initialState: .idle,
            event: .pauseRequested
        )

        assertRejected(
            initialState: .ready,
            event: .resumeRequested
        )

        assertRejected(
            initialState: .completed,
            event: .startRequested
        )
    }

    private func assertRejected(
        initialState: RideState,
        event: RideEvent,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var machine = RideStateMachine(
            initialState: initialState
        )

        XCTAssertThrowsError(
            try machine.handle(event),
            file: file,
            line: line
        )

        XCTAssertEqual(
            machine.state,
            initialState,
            file: file,
            line: line
        )
    }
}
