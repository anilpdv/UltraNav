import Foundation

/// Resource and structural limits enforced during GPX document streaming parsing.
public struct GPXParserLimits: Equatable, Sendable {
    public let maximumFileBytes: Int
    public let maximumElementDepth: Int
    public let maximumPointCount: Int
    public let maximumWaypointCount: Int
    public let maximumTextLength: Int
    public let maximumTrackCount: Int
    public let maximumSegmentCount: Int

    public init(
        maximumFileBytes: Int = 25 * 1024 * 1024,
        maximumElementDepth: Int = 64,
        maximumPointCount: Int = 500_000,
        maximumWaypointCount: Int = 10_000,
        maximumTextLength: Int = 32_768,
        maximumTrackCount: Int = 1_000,
        maximumSegmentCount: Int = 10_000
    ) {
        self.maximumFileBytes = maximumFileBytes
        self.maximumElementDepth = maximumElementDepth
        self.maximumPointCount = maximumPointCount
        self.maximumWaypointCount = maximumWaypointCount
        self.maximumTextLength = maximumTextLength
        self.maximumTrackCount = maximumTrackCount
        self.maximumSegmentCount = maximumSegmentCount
    }

    public static let watchStandard = GPXParserLimits(
        maximumFileBytes: 25 * 1024 * 1024,
        maximumElementDepth: 64,
        maximumPointCount: 500_000,
        maximumWaypointCount: 10_000,
        maximumTextLength: 32_768,
        maximumTrackCount: 1_000,
        maximumSegmentCount: 10_000
    )
}
