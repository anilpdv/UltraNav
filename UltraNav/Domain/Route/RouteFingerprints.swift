import Foundation

/// Pair of geometric identity and content fingerprints for route comparison and deduplication.
public struct RouteFingerprints: Equatable, Hashable, Codable, Sendable {
    public let geometryID: String
    public let contentFingerprint: String

    public init(geometryID: String, contentFingerprint: String) {
        self.geometryID = geometryID
        self.contentFingerprint = contentFingerprint
    }
}
