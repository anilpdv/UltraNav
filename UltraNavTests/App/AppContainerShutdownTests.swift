import XCTest
@testable import UltraNav

@MainActor
final class AppContainerShutdownTests: XCTestCase {

    func testContainerStopShutsDownCoordinatorsAndSetsStoppedState() async {
        let container = TestAppContainerBuilder().build()

        await container.start()
        XCTAssertEqual(container.lifecycle, .running)

        await container.stop()
        XCTAssertEqual(container.lifecycle, .stopped)
        XCTAssertFalse(container.coordinators.rideData.isActive)
        XCTAssertFalse(container.coordinators.routeNavigation.isActive)
        XCTAssertFalse(container.coordinators.notifications.isActive)
    }

    func testStopWhenNotRunningIsNoOp() async {
        let container = TestAppContainerBuilder().build()

        XCTAssertEqual(container.lifecycle, .created)
        await container.stop()
        XCTAssertEqual(container.lifecycle, .created)
    }

    func testRestartAfterStopSucceeds() async {
        let container = TestAppContainerBuilder().build()

        await container.start()
        XCTAssertEqual(container.lifecycle, .running)

        await container.stop()
        XCTAssertEqual(container.lifecycle, .stopped)

        await container.start()
        XCTAssertEqual(container.lifecycle, .running)
        XCTAssertTrue(container.coordinators.rideData.isActive)
    }
}
