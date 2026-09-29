import XCTest
@testable import UltraNav

final class GPXParsedModelTests: XCTestCase {
    func testTotalPointCountCalculatesCorrectly() {
        let seg1 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.0, longitude: -122.0),
            GPXParsedPoint(latitude: 37.1, longitude: -122.1)
        ])
        let seg2 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.2, longitude: -122.2)
        ])
        let track = GPXParsedTrack(name: "T1", segments: [seg1, seg2])

        let route = GPXParsedRoute(name: "R1", points: [
            GPXParsedPoint(latitude: 37.3, longitude: -122.3),
            GPXParsedPoint(latitude: 37.4, longitude: -122.4)
        ])

        let doc = GPXParsedDocument(
            tracks: [track],
            routes: [route],
            waypoints: [GPXParsedWaypoint(latitude: 37.5, longitude: -122.5)]
        )

        // Track points = 3, Route points = 2, totalPointCount = 5
        XCTAssertEqual(doc.totalPointCount, 5)
    }
}
