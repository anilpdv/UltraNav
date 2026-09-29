import Foundation

/// Result of importing and normalizing a route.
public struct RouteImportResult: Equatable, Sendable {
    public let route: Route
    public let warnings: [RouteNormalizationWarning]

    public init(route: Route, warnings: [RouteNormalizationWarning] = []) {
        self.route = route
        self.warnings = warnings
    }
}
