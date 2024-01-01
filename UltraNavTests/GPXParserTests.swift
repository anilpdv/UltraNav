import XCTest
import CoreLocation
@testable import UltraNav

final class GPXParserTests: XCTestCase {
    func testParseSimpleGPXTrackAndCues() throws {
        let sampleGPX = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="UltraNav">
          <trk>
            <name>Test Gravel Loop</name>
            <desc>A scenic test route</desc>
            <trkseg>
              <trkpt lat="37.3300" lon="-122.0000"><ele>100.0</ele></trkpt>
              <trkpt lat="37.3310" lon="-122.0005"><ele>110.0</ele></trkpt>
              <trkpt lat="37.3320" lon="-122.0010"><ele>125.0</ele></trkpt>
              <trkpt lat="37.3325" lon="-122.0030"><ele>130.0</ele></trkpt>
              <trkpt lat="37.3320" lon="-122.0050"><ele>120.0</ele></trkpt>
            </trkseg>
          </trk>
          <wpt lat="37.3320" lon="-122.0010">
            <name>Aid Station 1</name>
            <sym>water</sym>
          </wpt>
        </gpx>
        """

        let route = try GPXParser.parse(string: sampleGPX, defaultName: "Fallback")
        XCTAssertEqual(route.name, "Test Gravel Loop")
        XCTAssertEqual(route.summary, "A scenic test route")
        XCTAssertEqual(route.points.count, 5)
        XCTAssertGreaterThan(route.totalDistance, 100)
        XCTAssertEqual(route.minElevation, 100.0)
        XCTAssertEqual(route.maxElevation, 130.0)
        XCTAssertGreaterThanOrEqual(route.totalAscent, 30.0)

        // Verify Waypoint cue was parsed
        let waterCue = route.cues.first { $0.type == .water }
        XCTAssertNotNil(waterCue)
        XCTAssertEqual(waterCue?.instruction, "Aid Station 1")

        // Verify Start and End cues exist
        XCTAssertTrue(route.cues.contains { $0.type == .start })
        XCTAssertTrue(route.cues.contains { $0.type == .end })
    }

    func testClimbCategorization() {
        let route = SampleRoutes.alpineLoop
        XCTAssertFalse(route.climbs.isEmpty)
        let climb = route.climbs[0]
        XCTAssertEqual(climb.category, .cat2)
        XCTAssertGreaterThan(climb.length, 1000)
        XCTAssertGreaterThan(climb.elevationGain, 100)
        XCTAssertGreaterThan(climb.averageGradePercent, 3.0)
    }

    func testSampleRoutesAreValid() {
        for sample in SampleRoutes.all {
            XCTAssertFalse(sample.name.isEmpty)
            XCTAssertGreaterThan(sample.points.count, 10)
            XCTAssertGreaterThan(sample.totalDistance, 1000)
            XCTAssertFalse(sample.cues.isEmpty)
        }
    }
}
