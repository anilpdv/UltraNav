import Foundation

/// Parsed track (<trk>) containing track segments.
public struct GPXParsedTrack: Equatable, Hashable, Sendable {
    public let name: String?
    public let description: String?
    public let segments: [GPXParsedSegment]

    public init(
        name: String? = nil,
        description: String? = nil,
        segments: [GPXParsedSegment] = []
    ) {
        self.name = name
        self.description = description
        self.segments = segments
    }
}
