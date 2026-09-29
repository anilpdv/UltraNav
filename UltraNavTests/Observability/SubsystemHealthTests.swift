import Testing
import Foundation
@testable import UltraNav

@Suite("SubsystemHealth Tests")
struct SubsystemHealthTests {
    @Test("Subsystem health updates state and suppresses identical duplicate updates")
    func testSubsystemHealthUpdatesAndDeduplication() async {
        let center = ObservabilityCenter(clock: TestClock(), logger: TestLogger(), maximumEvents: 100)

        let initialHealth = SubsystemHealth(
            subsystem: .sensors,
            status: .healthy
        )
        await center.updateHealth(initialHealth)

        // Duplicate update with same status & properties
        await center.updateHealth(initialHealth)

        let snapshot1 = await center.snapshot()
        #expect(snapshot1.subsystemHealth[.sensors]?.status == .healthy)
        #expect(snapshot1.recentEvents.count == 1) // Duplicate suppressed

        // State change to degraded
        let degradedHealth = SubsystemHealth(
            subsystem: .sensors,
            status: .degraded,
            activeFailureID: .sensorDisconnected,
            activeDegradations: [.sensorDisconnected]
        )
        await center.updateHealth(degradedHealth)

        let snapshot2 = await center.snapshot()
        #expect(snapshot2.subsystemHealth[.sensors]?.status == .degraded)
        #expect(snapshot2.recentEvents.count == 2)
    }
}
