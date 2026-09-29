import XCTest
@testable import UltraNav

@MainActor
final class RouteMapViewModelTests: XCTestCase {
    func testRouteMapViewModelUpdatesFromNavigation() async {
        let route = NavigationRouteFactory.createLinearRoute(pointCount: 5)
        let navigation = NavigationEngine()
        await navigation.send(.useRoute(route))

        let viewModel = RouteMapViewModel(navigationEngine: navigation)
        XCTAssertEqual(viewModel.state.orientation.mode, .trackUp)

        viewModel.handle(.toggleOrientation)
        XCTAssertEqual(viewModel.state.orientation.mode, .northUp)

        viewModel.handle(.toggleOrientation)
        XCTAssertEqual(viewModel.state.orientation.mode, .trackUp)
    }
}
