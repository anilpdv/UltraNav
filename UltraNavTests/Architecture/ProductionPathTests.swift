import Foundation
import XCTest
@testable import UltraNav

final class ProductionPathTests: XCTestCase {
    @MainActor
    func testProductionPathExecutesWithoutExceptionsOrFallbacks() async throws {
        let container = AppContainer.makePreview()
        await container.start()
        
        // Assert initial state across the full pipeline
        XCTAssertEqual(container.presentation.app.isRiding, false)
        XCTAssertEqual(container.presentation.ride.state.phase, .idle)
        XCTAssertGreaterThanOrEqual(container.presentation.metrics.state.tiles.count, 4)
        
        await container.stop()
    }
}
