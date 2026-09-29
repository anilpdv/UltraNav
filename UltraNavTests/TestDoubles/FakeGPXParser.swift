import Foundation
@testable import UltraNav

final class FakeGPXParser: GPXParsing, @unchecked Sendable {
    var resultDocument: GPXParsedDocument?
    var errorToThrow: Error?
    private(set) var parseCallCount = 0

    init(resultDocument: GPXParsedDocument? = nil, errorToThrow: Error? = nil) {
        self.resultDocument = resultDocument
        self.errorToThrow = errorToThrow
    }

    func parse(data: Data) async throws -> GPXParsedDocument {
        let report = try await parseReport(data: data, sourceMetadata: nil)
        return report.document
    }

    func parseReport(data: Data, sourceMetadata: GPXSourceMetadata?) async throws -> GPXParsingReport {
        parseCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        let doc = resultDocument ?? GPXParsedDocument()
        return GPXParsingReport(
            document: doc,
            version: .version1_1,
            warnings: [],
            statistics: GPXDocumentStatistics(
                trackCount: doc.tracks.count,
                segmentCount: doc.tracks.reduce(0) { $0 + $1.segments.count },
                trackPointCount: doc.tracks.reduce(0) { $0 + $1.segments.reduce(0) { $0 + $1.points.count } },
                routeCount: doc.routes.count,
                routePointCount: doc.routes.reduce(0) { $0 + $1.points.count },
                waypointCount: doc.waypoints.count,
                pointsWithElevation: 0,
                pointsWithTimestamp: 0
            )
        )
    }
}
