import Foundation
import XCTest
@testable import UltraNav

final class StandardGPXContentSelectorTests: XCTestCase {
    private var selector: StandardGPXContentSelector!

    override func setUp() {
        super.setUp()
        selector = StandardGPXContentSelector()
    }

    override func tearDown() {
        selector = nil
        super.tearDown()
    }

    func testPreferTracksSelectsLongestTrackWhenMultipleExist() throws {
        let shortTrack = GPXParsedTrack(
            name: "Short Route",
            description: nil,
            segments: [GPXParsedSegment(points: [
                GPXParsedPoint(latitude: 37.0, longitude: -122.0),
                GPXParsedPoint(latitude: 37.1, longitude: -122.1)
            ])]
        )

        let longTrack = GPXParsedTrack(
            name: "Long Route",
            description: nil,
            segments: [GPXParsedSegment(points: [
                GPXParsedPoint(latitude: 37.0, longitude: -122.0),
                GPXParsedPoint(latitude: 37.1, longitude: -122.1),
                GPXParsedPoint(latitude: 37.2, longitude: -122.2)
            ])]
        )

        let doc = GPXParsedDocument(
            metadata: GPXSourceMetadata(),
            tracks: [shortTrack, longTrack],
            routes: [],
            waypoints: []
        )

        let selection = try selector.selectContent(from: doc, policy: .preferTracks)

        XCTAssertEqual(selection.selectedName, "Long Route")
        XCTAssertEqual(selection.segments.count, 1)
        XCTAssertEqual(selection.segments[0].points.count, 3)
        XCTAssertEqual(selection.sourceKind, .track)
        XCTAssertFalse(selection.warnings.isEmpty)
    }

    func testMergeAllTracksCombinesSegments() throws {
        let track1 = GPXParsedTrack(
            name: "Stage 1",
            description: nil,
            segments: [GPXParsedSegment(points: [
                GPXParsedPoint(latitude: 37.0, longitude: -122.0),
                GPXParsedPoint(latitude: 37.1, longitude: -122.1)
            ])]
        )

        let track2 = GPXParsedTrack(
            name: "Stage 2",
            description: nil,
            segments: [GPXParsedSegment(points: [
                GPXParsedPoint(latitude: 37.2, longitude: -122.2),
                GPXParsedPoint(latitude: 37.3, longitude: -122.3)
            ])]
        )

        let doc = GPXParsedDocument(
            metadata: GPXSourceMetadata(name: "Grand Tour"),
            tracks: [track1, track2],
            routes: [],
            waypoints: []
        )

        let selection = try selector.selectContent(from: doc, policy: .mergeAllTracks)

        XCTAssertEqual(selection.segments.count, 2)
        XCTAssertEqual(selection.sourceKind, .mergedTracks)
    }

    func testExtractCandidatesReturnsAccurateSummaries() {
        let track = GPXParsedTrack(
            name: "Ridge Loop",
            description: nil,
            segments: [
                GPXParsedSegment(points: [GPXParsedPoint(latitude: 37.0, longitude: -122.0)]),
                GPXParsedSegment(points: [GPXParsedPoint(latitude: 37.1, longitude: -122.1)])
            ]
        )

        let doc = GPXParsedDocument(
            metadata: GPXSourceMetadata(),
            tracks: [track],
            routes: [],
            waypoints: []
        )

        let candidates = selector.extractCandidates(from: doc)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].name, "Ridge Loop")
        XCTAssertEqual(candidates[0].pointCount, 2)
        XCTAssertEqual(candidates[0].segmentCount, 2)
    }
}
