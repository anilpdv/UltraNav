import Foundation
import XCTest
@testable import UltraNav

final class NavigationRegressionTests: XCTestCase {
    @MainActor
    func testNavigationRouteMatchingAndOffRouteEvaluation() async throws {
        let navEngine = NavigationEngine()
        let route = RouteFixture.straightRoute()
        
        await navEngine.send(.useRoute(route))
        XCTAssertEqual(navEngine.currentSnapshot.state, .ready)
        
        await navEngine.send(.start)
        XCTAssertEqual(navEngine.currentSnapshot.state, .navigating)
        
        // Feed on-route coordinate matching index 1
        let onRouteSample = LocationSample(
            coordinate: Coordinate(latitude: 24.7146, longitude: 46.6753),
            altitudeMeters: 602.0,
            horizontalAccuracyMeters: 2.0,
            verticalAccuracyMeters: 2.0,
            speedMetersPerSecond: 8.0,
            courseDegrees: 0.0,
            timestamp: TestDates.rideStart
        )
        navEngine.consume(location: onRouteSample)
        
        XCTAssertEqual(navEngine.currentSnapshot.offRouteStatus, .onRoute)
        XCTAssertGreaterThan(navEngine.currentSnapshot.distanceAlongRouteMeters, 0)
    }
}
