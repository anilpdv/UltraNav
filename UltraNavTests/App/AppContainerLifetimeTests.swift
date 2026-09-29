import XCTest
@testable import UltraNav

@MainActor
final class AppContainerLifetimeTests: XCTestCase {

    func testSharedEngineInstancesArePreservedAcrossContainer() {
        let container = TestAppContainerBuilder().build()

        XCTAssertTrue(container.engines.ride === container.engines.ride)
        XCTAssertTrue(container.engines.metrics === container.engines.metrics)
        XCTAssertTrue(container.engines.navigation === container.engines.navigation)
        XCTAssertTrue(container.engines.climb === container.engines.climb)
        XCTAssertTrue(container.engines.routeLibrary === container.engines.routeLibrary)
    }

    func testContainerRetainsCoordinators() {
        let container = TestAppContainerBuilder().build()

        XCTAssertNotNil(container.coordinators.rideData)
        XCTAssertNotNil(container.coordinators.rideLifecycle)
        XCTAssertNotNil(container.coordinators.routeNavigation)
        XCTAssertNotNil(container.coordinators.notifications)
    }
}
