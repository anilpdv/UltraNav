import Foundation
import XCTest
@testable import UltraNav

final class ClimbRegressionTests: XCTestCase {
    @MainActor
    func testClimbDetectionAndProgressTracking() async {
        let climbEngine = ClimbEngine()
        let climbRoute = RouteFixture.climbingRoute()
        
        await climbEngine.send(.loadRoute(climbRoute))
        XCTAssertTrue(climbEngine.currentSnapshot.state == .ready || climbEngine.currentSnapshot.state == .activeClimb)
        XCTAssertGreaterThan(climbEngine.currentSnapshot.totalClimbsCount, 0)
    }
}
