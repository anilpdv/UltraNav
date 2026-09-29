import Testing
import Foundation
@testable import UltraNav

@Suite("ObservabilityCenter Tests")
struct ObservabilityCenterTests {
    @Test("ObservabilityCenter records events and generates sequential sequence numbers")
    func testObservabilityCenterAssignsSequences() async {
        let clock = TestClock()
        let logger = TestLogger()
        let center = ObservabilityCenter(clock: clock, logger: logger, maximumEvents: 10)

        let event1 = DiagnosticEventFactory.makeEvent(category: .ride, kind: .custom("event 1"))
        let event2 = DiagnosticEventFactory.makeEvent(category: .navigation, kind: .custom("event 2"))

        await center.record(event1)
        await center.record(event2)

        let snapshot = await center.snapshot()
        #expect(snapshot.recentEvents.count == 2)
        #expect(snapshot.recentEvents[0].sequence == 1)
        #expect(snapshot.recentEvents[1].sequence == 2)

        let loggedEntries = await logger.entries
        #expect(loggedEntries.count == 2)
    }
}
