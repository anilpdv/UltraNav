import XCTest
@testable import UltraNav

@MainActor
final class RouteNavigationCoordinatorTests: XCTestCase {

    func testSelectRouteLoadsRouteAndForwardsToNavigationAndClimb() async throws {
        let fakeStore = FakeRouteStore()
        let fakeImporter = FakeRouteImporter()
        let routeLibrary = RouteLibraryEngine(store: fakeStore, importer: fakeImporter)
        let navigation = NavigationEngine(routeStore: fakeStore)
        let climb = ClimbEngine()

        let route = NavigationRouteFactory.createRoute(name: "Route One")
        _ = try await fakeStore.saveRoute(route, behavior: .overwriteExisting)

        let coordinator = RouteNavigationCoordinator(
            routeStore: fakeStore,
            routeLibraryEngine: routeLibrary,
            navigationEngine: navigation,
            climbEngine: climb
        )

        coordinator.activate()

        await coordinator.selectRoute(id: route.id)

        XCTAssertEqual(coordinator.activeRouteID, route.id)
        XCTAssertEqual(navigation.currentSnapshot.state, .ready)
        XCTAssertEqual(navigation.currentSnapshot.routeID, route.id)

        // Active route deletion is blocked
        XCTAssertFalse(coordinator.canDeleteRoute(id: route.id))

        await coordinator.clearRoute()
        XCTAssertNil(coordinator.activeRouteID)
        XCTAssertEqual(navigation.currentSnapshot.state, .inactive)
        XCTAssertTrue(coordinator.canDeleteRoute(id: route.id))

        coordinator.shutdown()
    }

    func testGenerationalLoadingPreventsStaleOverwrite() async throws {
        let fakeStore = FakeRouteStore()
        let fakeImporter = FakeRouteImporter()
        let routeLibrary = RouteLibraryEngine(store: fakeStore, importer: fakeImporter)
        let navigation = NavigationEngine(routeStore: fakeStore)
        let climb = ClimbEngine()

        let route1 = NavigationRouteFactory.createRoute(name: "Route One")
        let route2 = NavigationRouteFactory.createRoute(name: "Route Two")
        _ = try await fakeStore.saveRoute(route1, behavior: .overwriteExisting)
        _ = try await fakeStore.saveRoute(route2, behavior: .overwriteExisting)

        let coordinator = RouteNavigationCoordinator(
            routeStore: fakeStore,
            routeLibraryEngine: routeLibrary,
            navigationEngine: navigation,
            climbEngine: climb
        )

        await coordinator.selectRoute(id: route1.id)
        await coordinator.selectRoute(id: route2.id)

        XCTAssertEqual(coordinator.activeRouteID, route2.id)
        XCTAssertEqual(navigation.currentSnapshot.routeID, route2.id)
    }
}
