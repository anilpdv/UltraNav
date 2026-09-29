import Foundation
@testable import UltraNav

final class FakeClimbClassifier: ClimbClassifying, @unchecked Sendable {
    var stubbedCategory: ClimbCategory = .category3
    var classifyCallCount = 0

    func classify(candidate: ClimbCandidate) -> ClimbCategory {
        classifyCallCount += 1
        return stubbedCategory
    }
}
