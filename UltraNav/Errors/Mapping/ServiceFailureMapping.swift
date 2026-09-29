import Foundation

struct FailureClassification: Equatable, Sendable {
    let id: FailureID
    let severity: FailureSeverity
    let impact: FailureImpact
    let recoverability: FailureRecoverability
    let suggestedActions: [RecoveryAction]
    let diagnosticMessage: String?

    init(
        id: FailureID,
        severity: FailureSeverity,
        impact: FailureImpact,
        recoverability: FailureRecoverability,
        suggestedActions: [RecoveryAction],
        diagnosticMessage: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.impact = impact
        self.recoverability = recoverability
        self.suggestedActions = suggestedActions
        self.diagnosticMessage = diagnosticMessage
    }
}

protocol FailureClassifying: Sendable {
    associatedtype Failure: Error, Sendable
    func classify(failure: Failure, context: FailureContext) -> FailureClassification
}
