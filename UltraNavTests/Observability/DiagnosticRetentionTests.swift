import Testing
import Foundation
@testable import UltraNav

@Suite("DiagnosticRetention Tests")
struct DiagnosticRetentionTests {
    @Test("ObservabilityCenter enforces bounded maximum event limit")
    func testBoundedRetention() async {
        let maxLimit = 5
        let center = ObservabilityCenter(clock: TestClock(), logger: TestLogger(), maximumEvents: maxLimit)

        for i in 1...12 {
            let event = DiagnosticEvent(
                category: .ride,
                kind: .custom("event_\(i)"),
                severity: .information
            )
            await center.record(event)
        }

        let snapshot = await center.snapshot()
        #expect(snapshot.recentEvents.count == maxLimit)
        #expect(snapshot.recentEvents.first?.sequence == 8)
        #expect(snapshot.recentEvents.last?.sequence == 12)
    }
}
