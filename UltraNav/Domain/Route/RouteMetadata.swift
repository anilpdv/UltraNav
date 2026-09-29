import Foundation

/// Canonical metadata describing a Route.
public struct RouteMetadata: Equatable, Hashable, Codable, Sendable {
    public let name: String
    public let description: String?
    public let source: RouteSource
    public let importedAt: Date
    public let originalCreatedAt: Date?

    public init(
        name: String,
        description: String? = nil,
        source: RouteSource = .unknown,
        importedAt: Date = Date(),
        originalCreatedAt: Date? = nil
    ) {
        self.name = name
        self.description = description
        self.source = source
        self.importedAt = importedAt
        self.originalCreatedAt = originalCreatedAt
    }

    /// Convenience initializer for backwards compatibility
    public init(name: String, sourceFileName: String? = nil, createdAt: Date? = nil) {
        self.init(
            name: name,
            description: nil,
            source: sourceFileName != nil ? .importedGPX(originalFileName: sourceFileName!) : .unknown,
            importedAt: createdAt ?? Date(),
            originalCreatedAt: createdAt
        )
    }

    public var sourceFileName: String? {
        if case .importedGPX(let fileName) = source {
            return fileName
        }
        return nil
    }

    public var createdAt: Date? {
        originalCreatedAt ?? importedAt
    }
}
