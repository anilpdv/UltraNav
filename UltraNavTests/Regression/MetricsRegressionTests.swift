import Foundation
import XCTest
@testable import UltraNav

final class MetricsRegressionTests: XCTestCase {
    @MainActor
    func testMultiSourceMetricAggregation() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        
        let now = harness.clock.now
        
        // BLE power
        harness.engine.consume(sensor: SensorIdentifier(rawValue: "power-01"), sample: .power(watts: 310, timestamp: now))
        // HealthKit HR
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 160, timestamp: now))
        // CoreLocation Speed
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 11.2, timestamp: now))
        
        let snapshot = harness.engine.currentSnapshot
        XCTAssertEqual(snapshot.power?.value, 310)
        XCTAssertEqual(snapshot.heartRate?.value, 160)
        XCTAssertEqual(snapshot.speed?.value, 11.2)
    }
}
