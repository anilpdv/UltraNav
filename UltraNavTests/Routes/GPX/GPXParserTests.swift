import Foundation
import XCTest
@testable import UltraNav

final class GPXParserTests: XCTestCase {
    private var parser: GPXParserAdapter!

    override func setUp() {
        super.setUp()
        parser = GPXParserAdapter()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Versions & Namespaces

    func testParseGPX11WithDefaultNamespace() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="UltraNavTest" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>Test Course</name>
            <desc>Morning Training Ride</desc>
          </metadata>
          <trk>
            <name>Main Track</name>
            <trkseg>
              <trkpt lat="37.7749" lon="-122.4194"><ele>15.5</ele><time>2026-09-29T10:00:00Z</time></trkpt>
              <trkpt lat="37.7750" lon="-122.4195"><ele>16.0</ele><time>2026-09-29T10:00:05Z</time></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        XCTAssertEqual(report.version, .version1_1)
        XCTAssertEqual(report.document.metadata.name, "Test Course")
        XCTAssertEqual(report.document.metadata.description, "Morning Training Ride")
        XCTAssertEqual(report.document.metadata.creator, "UltraNavTest")
        XCTAssertEqual(report.document.tracks.count, 1)
        XCTAssertEqual(report.document.tracks[0].name, "Main Track")
        XCTAssertEqual(report.document.tracks[0].segments.count, 1)
        XCTAssertEqual(report.document.tracks[0].segments[0].points.count, 2)
        XCTAssertEqual(report.statistics.trackPointCount, 2)
        XCTAssertEqual(report.statistics.pointsWithElevation, 2)
        XCTAssertEqual(report.statistics.pointsWithTimestamp, 2)
    }

    func testParseGPX10WithPrefixedNamespace() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx:gpx version="1.0" creator="Strava" xmlns:gpx="http://www.topografix.com/GPX/1/0">
          <gpx:trk>
            <gpx:name>Prefixed Track</gpx:name>
            <gpx:trkseg>
              <gpx:trkpt lat="-33.8688" lon="151.2093"><gpx:ele>-5.0</gpx:ele></gpx:trkpt>
              <gpx:trkpt lat="-33.8689" lon="151.2094"><gpx:ele>-4.5</gpx:ele></gpx:trkpt>
            </gpx:trkseg>
          </gpx:trk>
        </gpx:gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        XCTAssertEqual(report.version, .version1_0)
        XCTAssertEqual(report.document.tracks.count, 1)
        XCTAssertEqual(report.document.tracks[0].name, "Prefixed Track")
        XCTAssertEqual(report.document.tracks[0].segments[0].points.count, 2)
        XCTAssertEqual(report.document.tracks[0].segments[0].points[0].elevationMeters, -5.0)
    }

    // MARK: - Multi-Segment & Multi-Track

    func testParseMultipleTracksAndSegments() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>Track 1</name>
            <trkseg>
              <trkpt lat="24.7136" lon="46.6753"></trkpt>
              <trkpt lat="24.7137" lon="46.6754"></trkpt>
            </trkseg>
            <trkseg>
              <trkpt lat="24.7140" lon="46.6757"></trkpt>
              <trkpt lat="24.7141" lon="46.6758"></trkpt>
            </trkseg>
          </trk>
          <trk>
            <name>Track 2</name>
            <trkseg>
              <trkpt lat="24.7150" lon="46.6760"></trkpt>
              <trkpt lat="24.7151" lon="46.6761"></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        XCTAssertEqual(report.document.tracks.count, 2)
        XCTAssertEqual(report.document.tracks[0].segments.count, 2)
        XCTAssertEqual(report.document.tracks[1].segments.count, 1)
        XCTAssertEqual(report.statistics.segmentCount, 3)
        XCTAssertEqual(report.statistics.trackPointCount, 6)
    }

    // MARK: - Routes and Waypoints

    func testParseRoutesAndWaypoints() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
          <wpt lat="37.7749" lon="-122.4194">
            <name>Sprint Finish</name>
            <desc>Finish Line Banner</desc>
            <sym>Flag</sym>
          </wpt>
          <rte>
            <name>Planned Route</name>
            <rtept lat="37.7700" lon="-122.4100"></rtept>
            <rtept lat="37.7710" lon="-122.4110"></rtept>
          </rte>
        </gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        XCTAssertEqual(report.document.waypoints.count, 1)
        XCTAssertEqual(report.document.waypoints[0].name, "Sprint Finish")
        XCTAssertEqual(report.document.waypoints[0].symbol, "Flag")
        XCTAssertEqual(report.document.routes.count, 1)
        XCTAssertEqual(report.document.routes[0].points.count, 2)
    }

    // MARK: - Tolerant Field Parsing & Warning Aggregation

    func testTolerantElevationAndTimestampParsing() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <trkseg>
              <!-- Point with valid fractional ISO timestamp -->
              <trkpt lat="24.7136" lon="46.6753"><ele>600.5</ele><time>2026-09-29T10:00:00.500Z</time></trkpt>
              <!-- Point with invalid elevation & malformed time -->
              <trkpt lat="24.7137" lon="46.6754"><ele>corrupted-elevation</ele><time>not-a-date</time></trkpt>
              <!-- Point with invalid coordinate (should be discarded) -->
              <trkpt lat="999.0" lon="46.6755"><ele>605.0</ele></trkpt>
              <!-- Point with valid timezone offset timestamp -->
              <trkpt lat="24.7138" lon="46.6756"><ele>602.0</ele><time>2026-09-29T13:00:00+03:00</time></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        // 3 usable points should remain (the 999.0 lat point was discarded)
        XCTAssertEqual(report.document.tracks[0].segments[0].points.count, 3)

        // Verify aggregated warnings
        XCTAssertTrue(report.warnings.contains { warning in
            if case .invalidElevationDiscarded(let count) = warning { return count == 1 }
            return false
        })
        XCTAssertTrue(report.warnings.contains { warning in
            if case .invalidTimestampDiscarded(let count) = warning { return count == 1 }
            return false
        })
        XCTAssertTrue(report.warnings.contains { warning in
            if case .invalidPointDiscarded(let count) = warning { return count == 1 }
            return false
        })
    }

    // MARK: - Vendor Extensions

    func testSafelyIgnoreUnknownVendorExtensions() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
          <trk>
            <trkseg>
              <trkpt lat="37.7749" lon="-122.4194">
                <ele>100.0</ele>
                <extensions>
                  <gpxtpx:TrackPointExtension>
                    <gpxtpx:hr>165</gpxtpx:hr>
                    <gpxtpx:cad>90</gpxtpx:cad>
                  </gpxtpx:TrackPointExtension>
                </extensions>
              </trkpt>
              <trkpt lat="37.7750" lon="-122.4195">
                <ele>101.0</ele>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = xml.data(using: .utf8)!
        let report = try await parser.parseReport(data: data, sourceMetadata: nil)

        XCTAssertEqual(report.document.tracks[0].segments[0].points.count, 2)
    }

    // MARK: - Safety Limits

    func testEnforceMaxFileBytesLimit() async {
        let limits = GPXParserLimits(maximumFileBytes: 100)
        let customParser = GPXParserAdapter(limits: limits)
        let largeData = Data(repeating: 0x20, count: 200)

        do {
            _ = try await customParser.parse(data: largeData)
            XCTFail("Expected fileTooLarge error")
        } catch let failure as GPXParserFailure {
            XCTAssertEqual(failure, .fileTooLarge(bytes: 200, limit: 100))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnforcePointCountLimit() async {
        let limits = GPXParserLimits(maximumPointCount: 2)
        let customParser = GPXParserAdapter(limits: limits)
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <trkseg>
              <trkpt lat="10.0" lon="10.0"></trkpt>
              <trkpt lat="10.1" lon="10.1"></trkpt>
              <trkpt lat="10.2" lon="10.2"></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = xml.data(using: .utf8)!

        do {
            _ = try await customParser.parse(data: data)
            XCTFail("Expected pointLimitExceeded error")
        } catch let failure as GPXParserFailure {
            XCTAssertEqual(failure, .pointLimitExceeded(limit: 2))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
