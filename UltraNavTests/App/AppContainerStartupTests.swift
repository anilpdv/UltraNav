import XCTest
@testable import UltraNav

@MainActor
final class AppContainerStartupTests: XCTestCase {

    func testContainerStartActivatesPlumbingAndSetsRunningState() async {
        let container = TestAppContainerBuilder().build()

        XCTAssertEqual(container.lifecycle, .created)
        XCTAssertFalse(container.coordinators.rideData.isActive)
        XCTAssertFalse(container.coordinators.routeNavigation.isActive)
        XCTAssertFalse(container.coordinators.notifications.isActive)

        await container.start()

        XCTAssertEqual(container.lifecycle, .running)
        XCTAssertTrue(container.coordinators.rideData.isActive)
        XCTAssertTrue(container.coordinators.routeNavigation.isActive)
        XCTAssertTrue(container.coordinators.notifications.isActive)
    }

    func testRepeatedStartIsIdempotent() async {
        let container = TestAppContainerBuilder().build()

        await container.start()
        XCTAssertEqual(container.lifecycle, .running)

        await container.start()
        XCTAssertEqual(container.lifecycle, .running)
    }
}
