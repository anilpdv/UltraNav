import Foundation

/// Output of a route normalization operation containing the canonical Route and any warnings.
public struct RouteNormalizationResult: Equatable, Sendable {
    public let route: Route
    public let warnings: [RouteNormalizationWarning]

    public init(route: Route, warnings: [RouteNormalizationWarning] = []) {
        self.route = route
        self.warnings = warnings
    }
}
