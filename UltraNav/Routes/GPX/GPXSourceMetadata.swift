import Foundation

/// Metadata extracted from a GPX document header.
public struct GPXSourceMetadata: Equatable, Hashable, Sendable {
    public let name: String?
    public let description: String?
    public let author: String?
    public let time: Date?
    public let creator: String?
    public let keywords: String?
    public let originalFileName: String?

    public init(
        name: String? = nil,
        description: String? = nil,
        author: String? = nil,
        time: Date? = nil,
        creator: String? = nil,
        keywords: String? = nil,
        originalFileName: String? = nil
    ) {
        self.name = name
        self.description = description
        self.author = author
        self.time = time
        self.creator = creator
        self.keywords = keywords
        self.originalFileName = originalFileName
    }
}
