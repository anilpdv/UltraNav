import Foundation

/// Pure assembler that converts ClimbCandidates into categorized Climb models.
struct ClimbAssembler: Sendable {
    private let classifier: ClimbClassifying

    init(classifier: ClimbClassifying = LegacyClimbClassifier()) {
        self.classifier = classifier
    }

    func assemble(candidates: [ClimbCandidate], routeID: Route.ID) -> [Climb] {
        let total = candidates.count
        guard total > 0 else { return [] }

        return candidates.enumerated().map { index, candidate in
            let climbIndex = index + 1
            let category = classifier.classify(candidate: candidate)
            let climbID = Climb.ID(routeID: routeID, climbIndex: climbIndex)

            return Climb(
                id: climbID,
                routeID: routeID,
                climbIndex: climbIndex,
                totalClimbs: total,
                startIndex: candidate.startIndex,
                endIndex: candidate.endIndex,
                startDistanceMeters: candidate.startDistanceMeters,
                endDistanceMeters: candidate.endDistanceMeters,
                startElevationMeters: candidate.startElevationMeters,
                summitElevationMeters: candidate.summitElevationMeters,
                elevationGainMeters: candidate.netElevationGainMeters,
                averageGradientRatio: candidate.averageGradientRatio,
                maximumGradientRatio: candidate.maximumGradientRatio,
                category: category,
                gradientSlices: candidate.slices
            )
        }
    }

    func assemble(candidates: [ClimbCandidate], routeID: UUID) -> [Climb] {
        assemble(candidates: candidates, routeID: RouteID(uuid: routeID))
    }
}
