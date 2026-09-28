import XCTest
import CoreLocation
@testable import UltraNav

@MainActor
final class NavigationEngineTests: XCTestCase {
    private var navigationEngine: NavigationEngine!

    override func setUp() async throws {
        try await super.setUp()
        navigationEngine = NavigationEngine()
    }

    func testLoadRouteInitializesNavigationState() {
        let route = SampleRoutes.alpineLoop
        navigationEngine.load(route: route)

        XCTAssertEqual(navigationEngine.navigationState, .navigating)
        XCTAssertEqual(navigationEngine.activeRoute?.id, route.id)
        XCTAssertEqual(navigationEngine.distanceRemainingMeters, route.totalDistance)
        XCTAssertFalse(navigationEngine.isOffCourse)
    }

    func testLocationUpdateCalculatesCrossTrackAndOffCourse() {
        let route = SampleRoutes.alpineLoop
        navigationEngine.load(route: route)

        let startPoint = route.points[0]
        let onCourseSample = LocationSample(
            coordinate: Coordinate(latitude: startPoint.coordinate.latitude, longitude: startPoint.coordinate.longitude),
            horizontalAccuracyMeters: 5,
            timestamp: Date(timeIntervalSince1970: 1000)
        )

        navigationEngine.update(location: onCourseSample)
        XCTAssertFalse(navigationEngine.isOffCourse)
        XCTAssertLessThanOrEqual(navigationEngine.crossTrackErrorMeters ?? 100, 5)

        // Simulate moving 100m away (Off Route)
        let offCourseSample = LocationSample(
            coordinate: Coordinate(latitude: startPoint.coordinate.latitude + 0.005, longitude: startPoint.coordinate.longitude + 0.005),
            horizontalAccuracyMeters: 5,
            timestamp: Date(timeIntervalSince1970: 1001)
        )

        navigationEngine.update(location: offCourseSample)
        XCTAssertTrue(navigationEngine.isOffCourse)
        XCTAssertEqual(navigationEngine.navigationState, .offRoute)
        XCTAssertGreaterThan(navigationEngine.crossTrackErrorMeters ?? 0, 35)
    }

    func testResetClearsRouteAndState() {
        let route = SampleRoutes.alpineLoop
        navigationEngine.load(route: route)

        navigationEngine.reset()

        XCTAssertEqual(navigationEngine.navigationState, .inactive)
        XCTAssertNil(navigationEngine.activeRoute)
        XCTAssertEqual(navigationEngine.distanceRemainingMeters, 0)
        XCTAssertTrue(navigationEngine.breadcrumbTrail.isEmpty)
    }
}
