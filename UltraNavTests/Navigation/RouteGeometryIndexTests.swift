import XCTest
@testable import UltraNav

final class RouteGeometryIndexTests: XCTestCase {

    func testGeometryIndexBuildsContinuousSegments() {
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3340, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 444)

        let route = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Test Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )

        let index = RouteGeometryIndex(route: route)

        XCTAssertEqual(index.edges.count, 2)
        XCTAssertEqual(index.edges[0].index, 0)
        XCTAssertEqual(index.edges[0].startDistanceMeters, 0.0)
        XCTAssertEqual(index.edges[0].endDistanceMeters, 222.0)
        XCTAssertEqual(index.edges[1].index, 1)
        XCTAssertEqual(index.edges[1].startDistanceMeters, 222.0)
        XCTAssertEqual(index.edges[1].endDistanceMeters, 444.0)
    }

    func testCandidateSearchWindowBoundedLocality() {
        var points: [RoutePoint] = []
        for i in 0...100 {
            let lat = 37.3300 + Double(i) * 0.001
            let dist = Double(i) * 111.0
            points.append(RoutePoint(coordinate: Coordinate(latitude: lat, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: dist))
        }

        let route = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Long Route"),
            points: points,
            totalDistanceMeters: 11100
        )

        let index = RouteGeometryIndex(route: route)
        XCTAssertEqual(index.edges.count, 100)

        // Near edge 50 with previousIndex = 50
        let target = Coordinate(latitude: 37.3800, longitude: -122.0100)
        let candidates = index.candidateEdges(near: target, searchRadiusMeters: 100.0, previousEdgeIndex: 50, forwardWindow: 10, backwardWindow: 5)

        // Window size should be bounded to 5 + 10 + 1 = 16 edges
        XCTAssertLessThanOrEqual(candidates.count, 16)
        XCTAssertTrue(candidates.contains(where: { $0.index == 50 }))
    }
}
