import Foundation

/// Candidate track or route available for selection within a multi-content GPX document.
public struct GPXContentCandidate: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: GPXContentKind
    public let name: String?
    public let pointCount: Int
    public let segmentCount: Int
    public let estimatedDistanceMeters: Double?

    public init(
        id: String,
        kind: GPXContentKind,
        name: String? = nil,
        pointCount: Int,
        segmentCount: Int,
        estimatedDistanceMeters: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.pointCount = pointCount
        self.segmentCount = segmentCount
        self.estimatedDistanceMeters = estimatedDistanceMeters
    }
}
