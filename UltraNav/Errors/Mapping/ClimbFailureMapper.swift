import Foundation

struct ClimbFailureMapper: FailureClassifying {
    typealias Failure = ClimbFailure

    func classify(failure: ClimbFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .noElevationData, .insufficientElevationData:
            return FailureClassification(
                id: FailureID(rawValue: "CLIMB-NO-ELEVATION"),
                severity: .informational,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.continueWithoutClimbData, .dismiss],
                diagnosticMessage: "Route does not contain elevation data; ClimbPro is unavailable"
            )

        case .routeUnavailable:
            return FailureClassification(
                id: FailureID(rawValue: "CLIMB-NO-ROUTE"),
                severity: .informational,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "No active route loaded for climb analysis"
            )

        case .profileConstructionFailed(let message), .climbDetectionFailed(let message), .invalidClimb(let message):
            return FailureClassification(
                id: .climbAnalysisFailed,
                severity: .warning,
                impact: .none,
                recoverability: .recoverableWithDegradation,
                suggestedActions: [.retry, .continueWithoutClimbData],
                diagnosticMessage: "Climb detection/analysis error: \(message)"
            )

        case .progressCalculationFailed(let message):
            return FailureClassification(
                id: .climbProgressFailed,
                severity: .warning,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Live climb progress tracking error: \(message)"
            )

        case .unexpected(let message):
            return FailureClassification(
                id: FailureID(rawValue: "CLIMB-UNEXPECTED-001"),
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Unexpected climb engine error: \(message)"
            )
        }
    }
}
