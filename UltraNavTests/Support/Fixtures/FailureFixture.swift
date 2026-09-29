import Foundation
@testable import UltraNav

/// Standardized failure reports, severity, and context fixtures.
enum FailureFixture {
    static func record(
        id: UUID = UUID(),
        failureID: FailureID = FailureID(rawValue: "test-failure-001"),
        failure: UltraNavFailure = .ride(.workoutPreparationFailed),
        severity: FailureSeverity = .warning,
        impact: FailureImpact = [.degradesActiveRide],
        recoverability: FailureRecoverability = .retryable,
        suggestedActions: [RecoveryAction] = [.retry],
        context: FailureContext = FailureContext(occurredAt: TestDates.rideStart, operation: .rideStart)
    ) -> FailureRecord {
        FailureRecord(
            id: id,
            failureID: failureID,
            failure: failure,
            severity: severity,
            impact: impact,
            recoverability: recoverability,
            suggestedActions: suggestedActions,
            context: context
        )
    }
}
