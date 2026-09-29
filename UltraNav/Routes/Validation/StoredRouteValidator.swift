import Foundation

/// Validates that a domain Route object satisfies all structural invariants before storage or navigation.
public final class StoredRouteValidator: RouteValidating, Sendable {
    private let validator = CanonicalRouteValidator()

    public init() {}

    public func validate(route: Route) throws {
        try validator.validate(route: route)
    }
}
