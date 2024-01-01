import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    @State private var selectedPage = 0

    private let pages = [
        OnboardingPage(
            systemImage: "location.fill",
            title: "Navigate from your wrist",
            message: "Find a destination and keep the next direction visible without reaching for your phone."
        ),
        OnboardingPage(
            systemImage: "arrow.triangle.turn.up.right.diamond.fill",
            title: "Focused directions",
            message: "UltraNav keeps essential route information concise and easy to read while you are moving."
        ),
        OnboardingPage(
            systemImage: "hand.raised.fill",
            title: "You control permissions",
            message: "Location and notification access are requested only when you use the features that need them."
        )
    ]

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 8) {
                        Image(systemName: page.systemImage)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)

                        Text(page.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(page.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)
                    .tag(index)
                    .accessibilityElement(children: .combine)
                }
            }
            .tabViewStyle(.verticalPage)

            Button(selectedPage == pages.count - 1 ? "Get Started" : "Continue") {
                if selectedPage == pages.count - 1 {
                    hasCompletedOnboarding = true
                } else {
                    if reduceMotion {
                        selectedPage += 1
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPage += 1
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(selectedPage == pages.count - 1 ? "Finishes setup" : "Shows the next introduction page")
            .accessibilityIdentifier("onboardingContinueButton")
            .minimumWatchTapTarget()
        }
        .navigationTitle("Welcome")
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let message: String
}

#Preview {
    OnboardingView()
}