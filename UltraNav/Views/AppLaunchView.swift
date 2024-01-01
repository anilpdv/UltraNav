import SwiftUI

struct AppLaunchView: View {
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    private var arguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    private var uiTestScenario: String? {
        guard let index = arguments.firstIndex(of: "-ui-test-scenario"),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    private var shouldShowOnboarding: Bool {
        if arguments.contains("-reset-onboarding") {
            return true
        }
        return !hasCompletedOnboarding
            && !arguments.contains("-completed-onboarding")
    }

    var body: some View {
        Group {
#if DEBUG
            if arguments.contains("-ui-testing"), let uiTestScenario {
                UITestScenarioView(scenario: uiTestScenario)
            } else if arguments.contains("-ui-testing"),
                      ProcessInfo.processInfo.environment["ULTRANAV_DEEP_LINK"] != nil {
                Text("Navigation")
                    .accessibilityIdentifier("navigationScreen")
            } else {
                applicationContent
            }
#else
            applicationContent
#endif
        }
    }

    @ViewBuilder
    private var applicationContent: some View {
        if shouldShowOnboarding {
            OnboardingView()
        } else {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel("Settings")
                            .accessibilityIdentifier("settingsButton")
                            .minimumWatchTapTarget()
                        }
                    }
            }
        }
    }
}

#if DEBUG
private struct UITestScenarioView: View {
    let scenario: String
    @State private var navigationStarted = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                switch scenario {
                case "route-preview":
                    if navigationStarted {
                        Text("Navigation active")
                            .accessibilityIdentifier("navigationStatus")
                    } else {
                        Button("Start") {
                            navigationStarted = true
                        }
                        .accessibilityIdentifier("startNavigationButton")
                    }
                case "empty-search":
                    Text("No destinations found")
                        .accessibilityIdentifier("emptySearchState")
                case "network-failure":
                    VStack {
                        Text("Search failed")
                            .accessibilityIdentifier("errorState")
                        Button("Retry") {}
                            .accessibilityIdentifier("retryButton")
                    }
                default:
                    Button("Settings") {
                        showingSettings = true
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .accessibilityIdentifier("navigationScreen")
            .navigationDestination(isPresented: $showingSettings) {
                Text("Transport Mode")
                    .navigationTitle("Settings")
            }
        }
    }
}
#endif

#Preview {
    AppLaunchView()
}
