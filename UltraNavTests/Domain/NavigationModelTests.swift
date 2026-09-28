import XCTest
@testable import UltraNav

final class NavigationModelTests: XCTestCase {
    func testInactiveSnapshotContainsNoCue() {
        let snapshot = NavigationSnapshot.inactive

        XCTAssertEqual(snapshot.state, .inactive)
        XCTAssertEqual(snapshot.routeProgress, 0)
        XCTAssertNil(snapshot.nextCue)
        XCTAssertNil(snapshot.crossTrackDistanceMeters)
        XCTAssertNil(snapshot.distanceToNextCueMeters)
    }
}
