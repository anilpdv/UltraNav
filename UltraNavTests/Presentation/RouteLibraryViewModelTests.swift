import XCTest
@testable import UltraNav

@MainActor
final class RouteLibraryViewModelTests: XCTestCase {
    func testRouteLibraryViewModelLoadsAndSelectsRoute() async {
        let store = FakeRouteStore()
        let importer = FakeRouteImporter()
        let library = RouteLibraryEngine(store: store, importer: importer)
        let navigation = NavigationEngine()
        let climb = ClimbEngine()
        let coordinator = RouteNavigationCoordinator(
            routeStore: store,
            routeLibraryEngine: library,
            navigationEngine: navigation,
            climbEngine: climb
        )

        let viewModel = RouteLibraryViewModel(
            routeLibraryEngine: library,
            routeNavigationCoordinator: coordinator,
            preferences: .metric
        )

        let route = NavigationRouteFactory.createLinearRoute(pointCount: 10)
        _ = try? await store.saveRoute(route, behavior: .overwriteExisting)

        viewModel.handle(.appeared)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.state.routes.count, 1)

        viewModel.handle(.routeSelected(route.id))
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(coordinator.activeRouteID, route.id)
    }
}
