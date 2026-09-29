import Foundation

/// Protocol for classifying a ClimbCandidate into a standardized ClimbCategory.
protocol ClimbClassifying: Sendable {
    func classify(candidate: ClimbCandidate) -> ClimbCategory
}
