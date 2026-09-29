import Foundation
@testable import UltraNav

@MainActor
final class NavigationEngineBuilder {
    var routeStore: (any RouteStoring)? = FakeRouteStore()
    var routeValidator: any NavigationRouteValidating = NavigationRouteValidator()
    var routeMatcher: any RouteMatching = RouteMatcher()
    var cueProvider: any NavigationCueProviding = NavigationCueBuilder()
    var cueProgressor: any CueProgressing = CueProgressor()
    var offRouteEvaluator: any OffRouteEvaluating = LegacyOffRouteEvaluator()
    var completionEvaluator: any RouteCompletionEvaluating = LegacyRouteCompletionEvaluator()

    func withRouteStore(_ store: any RouteStoring) -> Self {
        self.routeStore = store
        return self
    }

    func withRouteMatcher(_ matcher: any RouteMatching) -> Self {
        self.routeMatcher = matcher
        return self
    }

    func withCueProvider(_ provider: any NavigationCueProviding) -> Self {
        self.cueProvider = provider
        return self
    }

    func withOffRouteEvaluator(_ evaluator: any OffRouteEvaluating) -> Self {
        self.offRouteEvaluator = evaluator
        return self
    }

    func withCompletionEvaluator(_ evaluator: any RouteCompletionEvaluating) -> Self {
        self.completionEvaluator = evaluator
        return self
    }

    func build() -> NavigationEngine {
        NavigationEngine(
            routeStore: routeStore,
            routeValidator: routeValidator,
            routeMatcher: routeMatcher,
            cueProvider: cueProvider,
            cueProgressor: cueProgressor,
            offRouteEvaluator: offRouteEvaluator,
            completionEvaluator: completionEvaluator
        )
    }
}
