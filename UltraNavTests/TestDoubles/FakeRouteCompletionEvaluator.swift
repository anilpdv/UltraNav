import Foundation
@testable import UltraNav

final class FakeRouteCompletionEvaluator: RouteCompletionEvaluating, @unchecked Sendable {
    var isCompleted: Bool

    init(isCompleted: Bool = false) {
        self.isCompleted = isCompleted
    }

    func isRouteCompleted(
        route: Route,
        match: RouteMatch,
        location: LocationSample
    ) -> Bool {
        return isCompleted
    }
}
