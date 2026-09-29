import Foundation

protocol OffRouteEvaluating: Sendable {
    func evaluate(
        match: RouteMatch,
        previousStatus: OffRouteStatus,
        timestamp: Date
    ) -> OffRouteEvaluation
}
