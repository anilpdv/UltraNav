import Testing
import Foundation
@testable import UltraNav

@Suite("DiagnosticSnapshot Tests")
struct DiagnosticSnapshotTests {
    @Test("DiagnosticSnapshot compiles complete observability view")
    func testDiagnosticSnapshotCompilation() async {
        let fakeRecorder = FakeFailureRecorder()
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        let center = ObservabilityCenter(clock: clock, logger: TestLogger(), failureRecorder: fakeRecorder, maximumEvents: 50)

        await center.setApplicationState(.running)
        await center.increment(.routeImportsSucceeded, by: 3)
        await center.setGauge(.connectedSensorCount, value: 2.0)
        await center.updateHealth(SubsystemHealth(subsystem: .navigation, status: .healthy))

        let record = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            context: FailureContext(occurredAt: clock.now, operation: .sensorConnection)
        )
        await fakeRecorder.record(record)

        let snapshot = await center.snapshot()
        #expect(snapshot.applicationState == .running)
        #expect(snapshot.generatedAt == clock.now)
        #expect(snapshot.counters[.routeImportsSucceeded] == 3)
        #expect(snapshot.gauges[.connectedSensorCount] == 2.0)
        #expect(snapshot.subsystemHealth[.navigation]?.status == .healthy)
        #expect(snapshot.recentFailures.count == 1)
        #expect(snapshot.recentFailures[0].failureID == .sensorDisconnected)
    }
}
