import Foundation

/// Protocol isolating the conversion of parsed GPX documents into normalized domain Route objects.
public protocol RouteNormalizing: Sendable {
    func normalize(
        document: GPXParsedDocument,
        source: RouteSource,
        fallbackName: String,
        policy: RouteNormalizationPolicy
    ) throws -> RouteNormalizationResult
}
