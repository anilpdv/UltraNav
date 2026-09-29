import Foundation

struct NavigationFailureMapper: FailureClassifying {
    typealias Failure = NavigationFailure

    func classify(failure: NavigationFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .invalidRoute, .routeUnavailable:
            return FailureClassification(
                id: .navigationRouteMissing,
                severity: .high,
                impact: [.blocksNavigation, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.selectAnotherRoute, .continueWithoutNavigation],
                diagnosticMessage: "Navigation route is invalid or unavailable"
            )

        case .locationUnavailable:
            return FailureClassification(
                id: .locationTemporarilyUnknown,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Location sample unavailable for navigation matching"
            )

        case .calculationFailed:
            return FailureClassification(
                id: .navigationMatcherFailed,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Route matcher calculation failed"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "NAV-UNEXPECTED-001"),
                severity: .high,
                impact: .blocksNavigation,
                recoverability: .recoverableWithDegradation,
                suggestedActions: [.continueWithoutNavigation, .resetSubsystem],
                diagnosticMessage: "Unexpected navigation engine error"
            )
        }
    }
}
