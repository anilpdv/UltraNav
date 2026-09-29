import Foundation

/// Selected segment and waypoint content ready for normalization.
public struct GPXContentSelection: Equatable, Sendable {
    public let segments: [GPXParsedSegment]
    public let waypoints: [GPXParsedWaypoint]
    public let selectedName: String?
    public let selectedDescription: String?
    public let sourceKind: GPXContentKind
    public let warnings: [String]

    public init(
        segments: [GPXParsedSegment],
        waypoints: [GPXParsedWaypoint] = [],
        selectedName: String? = nil,
        selectedDescription: String? = nil,
        sourceKind: GPXContentKind,
        warnings: [String] = []
    ) {
        self.segments = segments
        self.waypoints = waypoints
        self.selectedName = selectedName
        self.selectedDescription = selectedDescription
        self.sourceKind = sourceKind
        self.warnings = warnings
    }
}
