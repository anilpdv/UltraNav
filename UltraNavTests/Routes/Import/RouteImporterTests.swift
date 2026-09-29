import XCTest
@testable import UltraNav

final class RouteImporterTests: XCTestCase {
    private var importer: RouteImporter!

    override func setUp() {
        super.setUp()
        importer = RouteImporter()
    }

    func testImportValidGPXDataSucceeds() async throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="UltraNav Test">
          <metadata><name>Import Test</name></metadata>
          <trk>
            <name>Track Test</name>
            <trkseg>
              <trkpt lat="37.3349" lon="-122.0090"><ele>100</ele></trkpt>
              <trkpt lat="37.3359" lon="-122.0090"><ele>110</ele></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """.data(using: .utf8)!

        let result = try await importer.importRoute(from: .data(gpx, originalFileName: "test.gpx"))
        XCTAssertEqual(result.route.metadata.name, "Import Test")
        XCTAssertEqual(result.route.points.count, 2)
        XCTAssertEqual(result.route.segments.count, 1)
        XCTAssertTrue(result.route.id.rawValue.hasPrefix("route-v1:"))
    }

    func testImportExceedingFileSizeLimitThrowsError() async {
        let bigData = Data(repeating: 0x41, count: 1024)
        let policy = RouteImportPolicy(limits: RouteImportLimits(maxFileSizeBytes: 512))

        do {
            _ = try await importer.importRoute(from: .data(bigData, originalFileName: "big.gpx"), policy: policy)
            XCTFail("Expected fileTooLarge error")
        } catch let failure as RouteImportFailure {
            guard case .fileTooLarge(let size, let limit) = failure else {
                XCTFail("Unexpected failure: \(failure)")
                return
            }
            XCTAssertEqual(size, 1024)
            XCTAssertEqual(limit, 512)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testImportMalformedGPXThrowsParsingFailed() async {
        let malformed = "NOT XML".data(using: .utf8)!

        do {
            _ = try await importer.importRoute(from: .data(malformed, originalFileName: "bad.gpx"))
            XCTFail("Expected parsingFailed error")
        } catch let failure as RouteImportFailure {
            guard case .parsingFailed = failure else {
                XCTFail("Unexpected failure: \(failure)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
