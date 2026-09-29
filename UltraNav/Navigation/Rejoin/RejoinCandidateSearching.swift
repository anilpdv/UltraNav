import Foundation

/// Protocol for finding and ranking potential rejoin candidates along a route geometry.
protocol RejoinCandidateSearching: Sendable {
    func candidates(
        index: RouteGeometryIndex,
        context: RejoinSearchContext,
        configuration: RejoinConfiguration
    ) async throws -> [RejoinCandidate]
}
