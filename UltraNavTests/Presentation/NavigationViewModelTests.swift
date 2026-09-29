import XCTest
@testable import UltraNav

@MainActor
final class NavigationViewModelTests: XCTestCase {
    func testNavigationViewModelMapsLoadedRouteAndActions() async {
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        let navigation = NavigationEngine()
        let library = RouteLibraryEngine()
        let store = FakeRouteStore()
        let climb = ClimbEngine()
        let coordinator = RouteNavigationCoordinator(
            routeStore: store,
            routeLibraryEngine: library,
            navigationEngine: navigation,
            climbEngine: climb
        )

        let viewModel = NavigationViewModel(
            navigationEngine: navigation,
            routeNavigationCoordinator: coordinator,
            preferences: .metric
        )

        XCTAssertEqual(viewModel.state.phase, .inactive)
        XCTAssertFalse(viewModel.state.canStart)

        // Load route into navigation
        await navigation.send(.useRoute(route))
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.state.phase, .ready)
        XCTAssertTrue(viewModel.state.canStart)

        // Start navigation
        viewModel.handle(.startSelected)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .navigating)
        XCTAssertTrue(viewModel.state.canStop)

        // Stop navigation (returns to ready state with route loaded)
        viewModel.handle(.stopSelected)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state.phase, .ready)
    }
}
