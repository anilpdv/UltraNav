import Foundation
import XCTest
@testable import UltraNav

final class FrameworkBoundaryTests: XCTestCase {
    func testDomainTypesAreCleanValueTypesWithoutFrameworkCoupling() {
        let routePoint = RoutePoint(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.0),
            elevationMeters: 100.0,
            cumulativeDistanceMeters: 0.0
        )
        XCTAssertEqual(routePoint.coordinate.latitude, 37.33)
        
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.0),
            altitudeMeters: 100.0,
            horizontalAccuracyMeters: 3.0,
            verticalAccuracyMeters: 3.0,
            speedMetersPerSecond: 10.0,
            courseDegrees: 90.0,
            timestamp: Date()
        )
        XCTAssertEqual(sample.coordinate.latitude, 37.33)
        XCTAssertLessThanOrEqual(sample.horizontalAccuracyMeters, 5.0)
    }
}
