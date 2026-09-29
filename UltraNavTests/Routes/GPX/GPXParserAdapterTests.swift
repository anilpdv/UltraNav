import XCTest
@testable import UltraNav

final class GPXParserAdapterTests: XCTestCase {
    private var parser: GPXParserAdapter!

    override func setUp() {
        super.setUp()
        parser = GPXParserAdapter()
    }

    func testParseEmptyDataThrowsEmptyDocument() async {
        do {
            _ = try await parser.parse(data: Data())
            XCTFail("Expected emptyDocument failure")
        } catch let failure as GPXParserFailure {
            XCTAssertEqual(failure, .emptyDocument)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testParseMalformedXMLThrowsMalformedError() async {
        let malformed = "<gpx><trk><name>Broken".data(using: .utf8)!
        do {
            _ = try await parser.parse(data: malformed)
            XCTFail("Expected malformed XML error")
        } catch let failure as GPXParserFailure {
            switch failure {
            case .xmlParserError, .malformedXML:
                // Success
                break
            default:
                XCTFail("Unexpected failure: \(failure)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testParseValidTrackExtractsMetadataSegmentsAndPoints() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Test">
          <metadata>
            <name>Course Alpha</name>
            <desc>Scenic loop</desc>
          </metadata>
          <trk>
            <name>Track 1</name>
            <trkseg>
              <trkpt lat="37.3349" lon="-122.0090"><ele>100.5</ele></trkpt>
              <trkpt lat="37.3355" lon="-122.0095"><ele>110.0</ele></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """.data(using: .utf8)!

        let doc = try await parser.parse(data: xml)

        XCTAssertEqual(doc.metadata.name, "Course Alpha")
        XCTAssertEqual(doc.metadata.description, "Scenic loop")
        XCTAssertEqual(doc.tracks.count, 1)
        XCTAssertEqual(doc.tracks[0].name, "Track 1")
        XCTAssertEqual(doc.tracks[0].segments.count, 1)
        XCTAssertEqual(doc.tracks[0].segments[0].points.count, 2)
        XCTAssertEqual(doc.tracks[0].segments[0].points[0].latitude, 37.3349, accuracy: 0.0001)
        XCTAssertEqual(doc.tracks[0].segments[0].points[0].longitude, -122.0090, accuracy: 0.0001)
        XCTAssertEqual(doc.tracks[0].segments[0].points[0].elevation, 100.5)
    }

    func testParseWaypointsExtractsPOIFields() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <wpt lat="37.4000" lon="-122.1000">
            <ele>250.0</ele>
            <name>Water Spring</name>
            <desc>Natural spring</desc>
            <sym>Water</sym>
          </wpt>
        </gpx>
        """.data(using: .utf8)!

        let doc = try await parser.parse(data: xml)

        XCTAssertEqual(doc.waypoints.count, 1)
        XCTAssertEqual(doc.waypoints[0].name, "Water Spring")
        XCTAssertEqual(doc.waypoints[0].description, "Natural spring")
        XCTAssertEqual(doc.waypoints[0].symbol, "Water")
        XCTAssertEqual(doc.waypoints[0].elevation, 250.0)
    }
}
