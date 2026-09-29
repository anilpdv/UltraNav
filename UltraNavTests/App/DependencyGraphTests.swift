import XCTest
@testable import UltraNav

@MainActor
final class DependencyGraphTests: XCTestCase {

    func testDependencyGraphHasNoMissingComponents() {
        let container = TestAppContainerBuilder().build()

        XCTAssertNotNil(container.infrastructure.clock)
        XCTAssertNotNil(container.infrastructure.haptics)
        XCTAssertNotNil(container.infrastructure.fileSystem)

        XCTAssertNotNil(container.services.location)
        XCTAssertNotNil(container.services.workout)
        XCTAssertNotNil(container.services.sensors)
        XCTAssertNotNil(container.services.routeStore)
        XCTAssertNotNil(container.services.routeImporter)

        XCTAssertNotNil(container.engines.ride)
        XCTAssertNotNil(container.engines.metrics)
        XCTAssertNotNil(container.engines.navigation)
        XCTAssertNotNil(container.engines.climb)
        XCTAssertNotNil(container.engines.routeLibrary)

        XCTAssertNotNil(container.coordinators.rideData)
        XCTAssertNotNil(container.coordinators.rideLifecycle)
        XCTAssertNotNil(container.coordinators.routeNavigation)
        XCTAssertNotNil(container.coordinators.notifications)

        XCTAssertNotNil(container.presentation.ride)
        XCTAssertNotNil(container.presentation.navigation)
        XCTAssertNotNil(container.presentation.metrics)
        XCTAssertNotNil(container.presentation.climb)
        XCTAssertNotNil(container.presentation.routeLibrary)
    }
}
