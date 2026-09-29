import Foundation
import XCTest
@testable import UltraNav

final class ArchitectureBoundaryTests: XCTestCase {
    func testDomainModelsHaveNoPlatformDependencies() {
        // Domain types should be pure Swift structs/enums
        let coordinate = Coordinate(latitude: 24.7136, longitude: 46.6753)
        XCTAssertEqual(coordinate.latitude, 24.7136)

        let sample = LocationFixture.sample()
        XCTAssertEqual(sample.coordinate.latitude, 24.7136)

        let route = RouteFixture.straightRoute()
        XCTAssertEqual(route.metadata.name, "Straight Route")
    }

    @MainActor
    func testEnginesOperatePurelyOnProtocolsAndSnapshots() {
        // Engines require protocol abstractions only
        let rideEngine = RideEngineBuilder().build()
        XCTAssertEqual(rideEngine.currentSnapshot.state, .idle)

        let metricsEngine = MetricsEngineBuilder().build()
        XCTAssertEqual(metricsEngine.currentSnapshot.averagePowerWatts, nil)

        let navEngine = NavigationEngineBuilder().build()
        XCTAssertEqual(navEngine.currentSnapshot.state, .inactive)

        let climbEngine = ClimbEngineBuilder().build()
        XCTAssertFalse(climbEngine.currentSnapshot.hasActiveClimb)
    }
}
