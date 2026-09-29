import Foundation
@testable import UltraNav

final class FakeCueProgressor: CueProgressing, @unchecked Sendable {
    var stubbedProgress: CueProgress

    init(stubbedProgress: CueProgress = CueProgress()) {
        self.stubbedProgress = stubbedProgress
    }

    func progress(
        cues: [NavigationCue],
        routeMatch: RouteMatch,
        previous: CueProgress?
    ) -> CueProgress {
        return stubbedProgress
    }
}
