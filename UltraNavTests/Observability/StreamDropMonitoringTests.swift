import Testing
import Foundation
@testable import UltraNav

@Suite("StreamDropMonitoring Tests")
struct StreamDropMonitoringTests {
    @Test("Stream drops record drop metrics safely")
    func testStreamDropRecord() async {
        let center = FakeObservabilityCenter()

        let drop = EventDropRecord(
            stream: .sensorMeasurements,
            droppedCount: 4,
            bufferCapacity: 64,
            eventClass: .measurement
        )

        let event = DiagnosticEvent(
            category: .bluetooth,
            kind: .eventDropped(drop),
            severity: .warning
        )

        await center.record(event)
        await center.increment(.streamEventsDropped, by: 4)

        let snapshot = await center.snapshot()
        #expect(snapshot.counters[.streamEventsDropped] == 4)
        #expect(snapshot.recentEvents.count == 1)

        if case .eventDropped(let recordedDrop) = snapshot.recentEvents[0].kind {
            #expect(recordedDrop.stream == .sensorMeasurements)
            #expect(recordedDrop.droppedCount == 4)
            #expect(recordedDrop.bufferCapacity == 64)
            #expect(recordedDrop.eventClass == .measurement)
        } else {
            Issue.record("Expected eventDropped kind")
        }
    }
}
