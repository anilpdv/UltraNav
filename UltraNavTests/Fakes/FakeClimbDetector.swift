import Foundation
@testable import UltraNav

final class FakeClimbDetector: ClimbDetecting, @unchecked Sendable {
    var stubbedCandidates: [ClimbCandidate] = []
    var stubbedError: ClimbFailure?
    var detectCallCount = 0

    func detectClimbs(in profile: ElevationProfile) throws -> [ClimbCandidate] {
        detectCallCount += 1
        if let error = stubbedError {
            throw error
        }
        return stubbedCandidates
    }
}
