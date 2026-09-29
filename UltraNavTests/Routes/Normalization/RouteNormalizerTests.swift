import Foundation
import XCTest
@testable import UltraNav

final class RouteNormalizerTests: XCTestCase {
    private var normalizer: RouteNormalizer!

    override func setUp() {
        super.setUp()
        normalizer = RouteNormalizer()
    }

    override func tearDown() {
        normalizer = nil
        super.tearDown()
    }

    func testPruneExactConsecutiveSampleDuplicates() throws {
        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let pts = [
            GPXParsedPoint(latitude: 37.0, longitude: -122.0, elevationMeters: 100.0, timestamp: timestamp),
            GPXParsedPoint(latitude: 37.0, longitude: -122.0, elevationMeters: 100.0, timestamp: timestamp), // Duplicate
            GPXParsedPoint(latitude: 37.001, longitude: -122.001, elevationMeters: 102.0, timestamp: timestamp.addingTimeInterval(5))
        ]

        let track = GPXParsedTrack(name: "Test", description: nil, segments: [GPXParsedSegment(points: pts)])
        let doc = GPXParsedDocument(metadata: GPXSourceMetadata(), tracks: [track], routes: [], waypoints: [])

        let result = try normalizer.normalize(
            document: doc,
            source: .importedGPX(originalFileName: "test.gpx"),
            fallbackName: "Fallback",
            policy: .default
        )

        XCTAssertEqual(result.route.points.count, 2)
        XCTAssertTrue(result.warnings.contains { warning in
            if case .duplicatePointsFiltered(let count) = warning { return count == 1 }
            return false
        })
    }

    func testCumulativeDistancesDoNotJumpAcrossSegmentGaps() throws {
        let seg1 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 37.000, longitude: -122.000),
            GPXParsedPoint(latitude: 37.001, longitude: -122.000) // ~111m
        ])

        let seg2 = GPXParsedSegment(points: [
            GPXParsedPoint(latitude: 38.000, longitude: -122.000), // ~111km gap from previous segment
            GPXParsedPoint(latitude: 38.001, longitude: -122.000) // ~111m
        ])

        let track = GPXParsedTrack(name: "Two Segments", description: nil, segments: [seg1, seg2])
        let doc = GPXParsedDocument(metadata: GPXSourceMetadata(), tracks: [track], routes: [], waypoints: [])

        let result = try normalizer.normalize(
            document: doc,
            source: .importedGPX(originalFileName: "test.gpx"),
            fallbackName: "Fallback",
            policy: .default
        )

        let route = result.route
        XCTAssertEqual(route.segments.count, 2)
        XCTAssertEqual(route.segments[0].startPointIndex, 0)
        XCTAssertEqual(route.segments[0].endPointIndex, 1)
        XCTAssertEqual(route.segments[1].startPointIndex, 2)
        XCTAssertEqual(route.segments[1].endPointIndex, 3)

        // The cumulative distance of the second segment start point should equal the end of the first segment
        let seg1EndDist = route.points[1].cumulativeDistanceMeters
        let seg2StartDist = route.points[2].cumulativeDistanceMeters
        XCTAssertEqual(seg1EndDist, seg2StartDist, accuracy: 0.001)

        // Total distance should be ~222m, NOT 111km!
        XCTAssertLessThan(route.totalDistanceMeters, 500.0)
    }

    func testAntimeridianCrossingDetection() throws {
        let pts = [
            GPXParsedPoint(latitude: 0.0, longitude: 179.9),
            GPXParsedPoint(latitude: 0.0, longitude: -179.9)
        ]

        let track = GPXParsedTrack(name: "Pacific Crossing", description: nil, segments: [GPXParsedSegment(points: pts)])
        let doc = GPXParsedDocument(metadata: GPXSourceMetadata(), tracks: [track], routes: [], waypoints: [])

        let result = try normalizer.normalize(
            document: doc,
            source: .importedGPX(originalFileName: "pacific.gpx"),
            fallbackName: "Pacific",
            policy: .default
        )

        XCTAssertTrue(result.warnings.contains { $0 == .antimeridianCrossingDetected })
    }
}
