import SwiftUI

struct RetryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String = "Try Again", action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel(title)
        .accessibilityHint("Attempts the failed action again")
        .accessibilityIdentifier("retryButton")
        .minimumWatchTapTarget()
    }
}