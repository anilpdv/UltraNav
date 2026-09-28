import XCTest
@testable import UltraNav

final class RouteModelTests: XCTestCase {
    func testRouteUsesInjectedIdentity() {
        let id = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!

        let route = Route(
            id: id,
            metadata: RouteMetadata(
                name: "Test Route",
                sourceFileName: "test.gpx",
                createdAt: nil
            ),
            points: [],
            totalDistanceMeters: 0
        )

        XCTAssertEqual(route.id, id)
    }
}
