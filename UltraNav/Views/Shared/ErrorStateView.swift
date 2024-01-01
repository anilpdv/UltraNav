import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let retryTitle: String
    let retryAction: () -> Void

    init(
        title: String = "Navigation unavailable",
        message: String,
        systemImage: String = "exclamationmark.triangle",
        retryTitle: String = "Try Again",
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            RetryButton(retryTitle, action: retryAction)
        }
        .accessibilityElement(children: .contain)
    }
}