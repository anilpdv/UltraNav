import Foundation

struct FailureViewState: Equatable, Sendable {
    let title: String
    let message: String
    let severity: FailureSeverity
    let isDismissable: Bool
    let primaryAction: RecoveryActionViewState?
    let secondaryAction: RecoveryActionViewState?

    init(
        title: String,
        message: String,
        severity: FailureSeverity,
        isDismissable: Bool = true,
        primaryAction: RecoveryActionViewState? = nil,
        secondaryAction: RecoveryActionViewState? = nil
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.isDismissable = isDismissable
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    static let none = FailureViewState(title: "", message: "", severity: .informational, isDismissable: true)
}
