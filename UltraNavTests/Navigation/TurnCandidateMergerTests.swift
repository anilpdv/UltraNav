import XCTest
@testable import UltraNav

final class TurnCandidateMergerTests: XCTestCase {
    func testMergesCloselySpacedCandidatesIntoCompoundTurn() {
        let coord1 = Coordinate(latitude: 37.3310, longitude: -122.0100)
        let coord2 = Coordinate(latitude: 37.3311, longitude: -122.0099)

        // Two +45° slight rights within 10 meters of each other -> compound +90° right turn
        let c1 = TurnCandidate(distanceAlongRouteMeters: 100.0, coordinate: coord1, turnAngleDegrees: 45.0, maneuver: .slightRight)
        let c2 = TurnCandidate(distanceAlongRouteMeters: 108.0, coordinate: coord2, turnAngleDegrees: 45.0, maneuver: .slightRight)

        let merger = TurnCandidateMerger(clusterThresholdMeters: 25.0)
        let merged = merger.merge(candidates: [c1, c2])

        XCTAssertEqual(merged.count, 1)
        if let turn = merged.first {
            XCTAssertEqual(turn.maneuver, .right)
            XCTAssertEqual(turn.turnAngleDegrees, 90.0, accuracy: 1.0)
        }
    }

    func testDistantCandidatesAreNotMerged() {
        let coord1 = Coordinate(latitude: 37.3310, longitude: -122.0100)
        let coord2 = Coordinate(latitude: 37.3350, longitude: -122.0100)

        let c1 = TurnCandidate(distanceAlongRouteMeters: 100.0, coordinate: coord1, turnAngleDegrees: 90.0, maneuver: .right)
        let c2 = TurnCandidate(distanceAlongRouteMeters: 300.0, coordinate: coord2, turnAngleDegrees: -90.0, maneuver: .left)

        let merger = TurnCandidateMerger(clusterThresholdMeters: 25.0)
        let merged = merger.merge(candidates: [c1, c2])

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[0].maneuver, .right)
        XCTAssertEqual(merged[1].maneuver, .left)
    }
}
