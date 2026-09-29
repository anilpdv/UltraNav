import Foundation

/// Protocol for validating parsed GPX document structure prior to normalization.
public protocol ParsedRouteValidating: Sendable {
    func validate(document: GPXParsedDocument, policy: ParsedRouteValidationPolicy) throws
}
