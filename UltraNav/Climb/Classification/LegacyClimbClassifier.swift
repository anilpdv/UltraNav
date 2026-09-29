import Foundation

/// Legacy classifier based on GPXParser score and gain thresholds.
struct LegacyClimbClassifier: ClimbClassifying {
    init() {}

    func classify(candidate: ClimbCandidate) -> ClimbCategory {
        let distance = candidate.lengthMeters
        let gain = candidate.netElevationGainMeters
        let score = distance * (gain / max(1.0, distance) * 100.0)

        if score > 80000 || gain > 1000 { return .horsCategorie }
        if score > 64000 || gain > 600 { return .category1 }
        if score > 32000 || gain > 350 { return .category2 }
        if score > 16000 || gain > 180 { return .category3 }
        if score > 8000 || gain > 70 { return .category4 }
        return .uncategorized
    }
}
