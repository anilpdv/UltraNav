import XCTest
@testable import UltraNav

final class RouteNormalizerTests: XCTestCase {
    private var normalizer: RouteNormalizer!

    override func setUp() {
        super.setUp()
        normalizer = RouteNormalizer()
    }

    func testNormalizeTrackWithMultipleSegmentsDoesNotAddGapDistance() throws {
        // Seg 1: (37.3349, -122.0090) to (37.3359, -122.0090) ~111 meters
        let seg1 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.3349, longitude: -122.0090, elevation: 100),
            GPXParsedPoint(latitude: 37.3359, longitude: -122.0090, elevation: 105)
        ])

        // Seg 2: (37.4000, -122.0090) to (37.4010, -122.0090) ~111 meters
        // Note: Distance between (37.3359) and (37.4000) is ~7100m, which MUST NOT be added!
        let seg2 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.4000, longitude: -122.0090, elevation: 200),
            GPXParsedPoint(latitude: 37.4010, longitude: -122.0090, elevation: 205)
        ])

        let track = GPXParsedTrack(name: "Multi-Seg", segments: [seg1, seg2])
        let doc = GPXParsedDocument(tracks: [track])

        let result = try normalizer.normalize(
            document: doc,
            source: .importedGPX(originalFileName: "multi.gpx"),
            fallbackName: "Multi",
            policy: .default
        )

        let route = result.route
        XCTAssertEqual(route.segments.count, 2)
        XCTAssertEqual(route.points.count, 4)

        // Total distance should be ~222 meters (111m + 111m), definitely under 500 meters, NOT 7300+ meters!
        XCTAssertLessThan(route.totalDistanceMeters, 500.0)
        XCTAssertGreaterThan(route.totalDistanceMeters, 200.0)

        // Cumulative distance at point 2 (start of seg 2) should match cumulative distance at point 1 (end of seg 1)
        XCTAssertEqual(route.points[2].cumulativeDistanceMeters, route.points[1].cumulativeDistanceMeters, accuracy: 0.001)
    }

    func testNormalizeFiltersDuplicateNearbyPoints() throws {
        // Points spaced 0.1m apart
        let seg = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.334900, longitude: -122.009000),
            GPXParsedPoint(latitude: 37.334901, longitude: -122.009000), // ~0.11m apart
            GPXParsedPoint(latitude: 37.335900, longitude: -122.009000)
        ])
        let doc = GPXParsedDocument(tracks: [GPXParsedTrack(segments: [seg])])

        let result = try normalizer.normalize(
            document: doc,
            source: .generated,
            fallbackName: "Filtered",
            policy: RouteNormalizationPolicy(minimumPointSpacingMeters: 0.5)
        )

        XCTAssertEqual(result.route.points.count, 2)
        XCTAssertTrue(result.warnings.contains(where: {
            if case .duplicatePointsFiltered(let count) = $0 { return count == 1 }
            return false
        }))
    }
}
