import Foundation

/// Read content and metadata ready for parsing.
public struct RouteSourceContent: Sendable {
    public let data: Data
    public let source: RouteSource
    public let fallbackName: String

    public init(data: Data, source: RouteSource, fallbackName: String) {
        self.data = data
        self.source = source
        self.fallbackName = fallbackName
    }
}
