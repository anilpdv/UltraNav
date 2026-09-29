import Foundation
import XCTest
@testable import UltraNav

/// Focused assertions for NavigationEngine snapshots.
func assertNavigationNavigating(
    _ snapshot: NavigationSnapshot,
    routeID: Route.ID? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .navigating, "Expected navigation state to be .navigating, got \(snapshot.state)", file: file, line: line)
    XCTAssertEqual(snapshot.offRouteStatus, .onRoute, "Expected snapshot.offRouteStatus to be .onRoute, got \(snapshot.offRouteStatus)", file: file, line: line)
    if let expectedID = routeID {
        XCTAssertEqual(snapshot.routeID, expectedID, "Expected routeID \(expectedID), got \(String(describing: snapshot.routeID))", file: file, line: line)
    }
}

func assertNavigationOffRoute(
    _ snapshot: NavigationSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .navigating, "Expected navigation state to be .navigating, got \(snapshot.state)", file: file, line: line)
    XCTAssertEqual(snapshot.offRouteStatus, .offRoute, "Expected snapshot.offRouteStatus to be .offRoute, got \(snapshot.offRouteStatus)", file: file, line: line)
}

func assertNavigationFinished(
    _ snapshot: NavigationSnapshot,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(snapshot.state, .finished, "Expected navigation state to be .finished, got \(snapshot.state)", file: file, line: line)
}
