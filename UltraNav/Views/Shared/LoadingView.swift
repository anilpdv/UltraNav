import SwiftUI

struct LoadingView: View {
    let title: String
    let message: String?

    init(_ title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.large)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        [title, message].compactMap { $0 }.joined(separator: ". ")
    }
}