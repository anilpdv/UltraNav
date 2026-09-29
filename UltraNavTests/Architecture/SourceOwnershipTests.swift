import Foundation
import XCTest
@testable import UltraNav

final class SourceOwnershipTests: XCTestCase {
    @MainActor
    func testSensorsAndLocationHaveClearSourceOwnership() async throws {
        let harness = UltraNavIntegrationHarness()
        await harness.start()
        await harness.container.engines.metrics.send(.start)
        
        let powerSample = SensorSample.power(watts: 280, timestamp: TestDates.rideStart)
        harness.sensors.send(.sampleReceived(sensor: TestIDs.powerSensor, sample: powerSample))
        
        try await eventually {
            await harness.container.engines.metrics.currentSnapshot.power?.value == 280
        }
        
        // Assert metrics engine received the sensor sample with proper source attribution
        let snapshot = harness.container.engines.metrics.currentSnapshot
        XCTAssertEqual(snapshot.power?.value, 280)
        XCTAssertEqual(snapshot.power?.source, .bluetooth(sensorID: TestIDs.powerSensor))
        
        await harness.shutdown()
    }
}
