import Foundation

@MainActor
protocol FailureRecovering: AnyObject, Sendable {
    func perform(action: RecoveryAction, for record: FailureRecord) async -> RecoveryResult
}
