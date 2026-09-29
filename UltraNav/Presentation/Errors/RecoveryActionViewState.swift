import Foundation

struct RecoveryActionViewState: Equatable, Sendable {
    let title: String
    let action: RecoveryAction
    let isDestructive: Bool

    init(title: String, action: RecoveryAction, isDestructive: Bool = false) {
        self.title = title
        self.action = action
        self.isDestructive = isDestructive
    }
}
