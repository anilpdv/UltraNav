import Foundation
@testable import UltraNav

final class FakeOffRouteEvaluator: OffRouteEvaluating, @unchecked Sendable {
    var stubbedEvaluation: OffRouteEvaluation

    init(stubbedEvaluation: OffRouteEvaluation = OffRouteEvaluation(status: .onRoute, shouldNotify: false)) {
        self.stubbedEvaluation = stubbedEvaluation
    }

    func evaluate(
        match: RouteMatch,
        previousStatus: OffRouteStatus,
        timestamp: Date
    ) -> OffRouteEvaluation {
        return stubbedEvaluation
    }
}
