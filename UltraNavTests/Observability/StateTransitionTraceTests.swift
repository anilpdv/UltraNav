import Testing
import Foundation
@testable import UltraNav

@Suite("StateTransitionTrace Tests")
struct StateTransitionTraceTests {
    @Test("StateTransitionTrace contains expected metadata and subsystem classification")
    func testStateTransitionTrace() async {
        let center = FakeObservabilityCenter()

        let event = DiagnosticEvent(
            category: .ride,
            kind: .stateTransition(
                StateTransitionTrace(
                    subsystem: .ride,
                    fromState: "ready",
                    event: "startRequested",
                    toState: "active",
                    changedState: true
                )
            ),
            severity: .information
        )

        await center.record(event)

        let events = await center.recordedEvents
        #expect(events.count == 1)
        if case .stateTransition(let trace) = events[0].kind {
            #expect(trace.subsystem == .ride)
            #expect(trace.fromState == "ready")
            #expect(trace.event == "startRequested")
            #expect(trace.toState == "active")
            #expect(trace.changedState == true)
        } else {
            Issue.record("Expected stateTransition trace")
        }
    }
}
