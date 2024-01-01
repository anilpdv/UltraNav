import SwiftUI

struct EmptyStateView<Actions: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder private let actions: () -> Actions

    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actions = actions
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            actions()
        }
        .accessibilityElement(children: .contain)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(
        title: String,
        message: String,
        systemImage: String = "tray"
    ) {
        self.init(
            title: title,
            message: message,
            systemImage: systemImage
        ) {
            EmptyView()
        }
    }
}