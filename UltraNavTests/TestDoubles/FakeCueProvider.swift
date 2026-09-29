import Foundation
@testable import UltraNav

final class FakeCueProvider: NavigationCueProviding, @unchecked Sendable {
    var cues: [NavigationCue]

    init(cues: [NavigationCue] = []) {
        self.cues = cues
    }

    func cues(for route: Route) -> [NavigationCue] {
        return cues
    }
}
