import XCTest
@testable import UltraNav

@MainActor
final class ClimbViewModelTests: XCTestCase {
    func testClimbViewModelMapsElevationProfileAndClimbs() async {
        let climb = ClimbEngine()
        let viewModel = ClimbViewModel(climbEngine: climb, preferences: .metric)

        XCTAssertEqual(viewModel.state.phase, .unavailable)

        let route = NavigationRouteFactory.createLinearRoute(pointCount: 10)
        await climb.send(.loadRoute(route))
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotEqual(viewModel.state.phase, .unavailable)
    }
}
