import Foundation

/// Document statistics gathered during GPX parsing.
public struct GPXDocumentStatistics: Equatable, Sendable {
    public let trackCount: Int
    public let segmentCount: Int
    public let trackPointCount: Int
    public let routeCount: Int
    public let routePointCount: Int
    public let waypointCount: Int
    public let pointsWithElevation: Int
    public let pointsWithTimestamp: Int

    public init(
        trackCount: Int = 0,
        segmentCount: Int = 0,
        trackPointCount: Int = 0,
        routeCount: Int = 0,
        routePointCount: Int = 0,
        waypointCount: Int = 0,
        pointsWithElevation: Int = 0,
        pointsWithTimestamp: Int = 0
    ) {
        self.trackCount = trackCount
        self.segmentCount = segmentCount
        self.trackPointCount = trackPointCount
        self.routeCount = routeCount
        self.routePointCount = routePointCount
        self.waypointCount = waypointCount
        self.pointsWithElevation = pointsWithElevation
        self.pointsWithTimestamp = pointsWithTimestamp
    }
}

/// Comprehensive report emitted by GPX parser.
public struct GPXParsingReport: Equatable, Sendable {
    public let document: GPXParsedDocument
    public let version: GPXVersion?
    public let warnings: [GPXParserWarning]
    public let statistics: GPXDocumentStatistics

    public init(
        document: GPXParsedDocument,
        version: GPXVersion? = nil,
        warnings: [GPXParserWarning] = [],
        statistics: GPXDocumentStatistics = GPXDocumentStatistics()
    ) {
        self.document = document
        self.version = version
        self.warnings = warnings
        self.statistics = statistics
    }
}
