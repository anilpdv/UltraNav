import Foundation
import XCTest
@testable import UltraNav

final class GPXLargeFileTests: XCTestCase {
    func testParseAndNormalize10000PointRoute() async throws {
        let largeData = GPXLargeFixtureGenerator.makeTrack(pointCount: 10_000, segmentCount: 4)

        let parser = GPXParserAdapter()
        let report = try await parser.parseReport(data: largeData, sourceMetadata: nil)

        XCTAssertEqual(report.statistics.trackPointCount, 10_000)
        XCTAssertEqual(report.document.tracks[0].segments.count, 4)

        let normalizer = RouteNormalizer()
        let normResult = try normalizer.normalize(
            document: report.document,
            source: .importedGPX(originalFileName: "stress_10k.gpx"),
            fallbackName: "10k Route"
        )

        XCTAssertEqual(normResult.route.points.count, 10_000)
        XCTAssertEqual(normResult.route.segments.count, 4)

        let validator = CanonicalRouteValidator()
        XCTAssertNoThrow(try validator.validate(route: normResult.route))
    }
}
