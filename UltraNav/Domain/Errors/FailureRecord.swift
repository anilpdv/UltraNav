import Foundation

struct FailureRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let failureID: FailureID
    let failure: UltraNavFailure
    let severity: FailureSeverity
    let impact: FailureImpact
    let recoverability: FailureRecoverability
    let suggestedActions: [RecoveryAction]
    let context: FailureContext
    let diagnosticMessage: String?
    let occurrenceCount: Int

    init(
        id: UUID = UUID(),
        failureID: FailureID,
        failure: UltraNavFailure,
        severity: FailureSeverity,
        impact: FailureImpact,
        recoverability: FailureRecoverability,
        suggestedActions: [RecoveryAction],
        context: FailureContext,
        diagnosticMessage: String? = nil,
        occurrenceCount: Int = 1
    ) {
        self.id = id
        self.failureID = failureID
        self.failure = failure
        self.severity = severity
        self.impact = impact
        self.recoverability = recoverability
        self.suggestedActions = suggestedActions
        self.context = context
        self.diagnosticMessage = diagnosticMessage
        self.occurrenceCount = occurrenceCount
    }
}
