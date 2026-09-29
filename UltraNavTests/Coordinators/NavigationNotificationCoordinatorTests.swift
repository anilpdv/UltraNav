import XCTest
@testable import UltraNav

@MainActor
final class NavigationNotificationCoordinatorTests: XCTestCase {

    func testNavigationNotificationsMapToHapticPatterns() async {
        let navigation = NavigationEngine()
        let climb = ClimbEngine()
        let fakeHaptics = FakeHapticProvider()

        let coordinator = NavigationNotificationCoordinator(
            navigationEngine: navigation,
            climbEngine: climb,
            haptics: fakeHaptics
        )

        let cue = NavigationRouteFactory.createCue(maneuver: .left, distanceMeters: 50, instruction: "Turn left")

        await coordinator.handle(navigationNotification: .approachingCue(cue))
        let pattern1 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern1, .turnApproaching)

        await coordinator.handle(navigationNotification: .immediateCue(cue))
        let pattern2 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern2, .turnImmediate)

        await coordinator.handle(navigationNotification: .offRoute)
        let pattern3 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern3, .offRoute)

        await coordinator.handle(navigationNotification: .routeRejoined)
        let pattern4 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern4, .routeRejoined)

        await coordinator.handle(navigationNotification: .routeCompleted)
        let pattern5 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern5, .rideFinished)
    }

    func testClimbNotificationsMapToHapticPatterns() async {
        let navigation = NavigationEngine()
        let climb = ClimbEngine()
        let fakeHaptics = FakeHapticProvider()

        let coordinator = NavigationNotificationCoordinator(
            navigationEngine: navigation,
            climbEngine: climb,
            haptics: fakeHaptics
        )

        let testClimb = ClimbFactory.makeClimb(category: .category3)

        await coordinator.handle(climbNotification: .climbApproaching(climb: testClimb, distanceMeters: 200))
        let pattern1 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern1, .climbApproaching)

        await coordinator.handle(climbNotification: .climbStarted(climb: testClimb))
        let pattern2 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern2, .climbStarted)

        await coordinator.handle(climbNotification: .climbCompleted(climb: testClimb))
        let pattern3 = await fakeHaptics.playedPatterns.last
        XCTAssertEqual(pattern3, .climbCompleted)
    }
}
