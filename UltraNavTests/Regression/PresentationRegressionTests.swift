import Foundation
import XCTest
@testable import UltraNav

final class PresentationRegressionTests: XCTestCase {
    @MainActor
    func testPresentationViewModelsReflectEngineSnapshots() async {
        let container = AppContainer.makePreview()
        await container.start()
        
        XCTAssertEqual(container.presentation.ride.state.phase, .idle)
        XCTAssertGreaterThanOrEqual(container.presentation.metrics.state.tiles.count, 4)
        XCTAssertEqual(container.presentation.navigation.state.phase, .inactive)
        XCTAssertEqual(container.presentation.climb.state.phase, .unavailable)
        
        await container.stop()
    }
}
