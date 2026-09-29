import SwiftUI
import WatchKit

@main
struct UltraNavApp: App {
    @WKApplicationDelegateAdaptor(UltraNavApplicationDelegate.self)
    private var applicationDelegate

    @State private var container: AppContainer
    @State private var navigationModel = NavigationModel()
    @State private var cyclingEngine = CyclingRideEngine.shared

    init() {
        do {
            let container = try AppContainer.makeProduction()
            _container = State(initialValue: container)
        } catch {
            let fallback = AppContainer.makePreview()
            _container = State(initialValue: fallback)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
                .environment(navigationModel)
                .environment(cyclingEngine)
                .task {
                    await container.start()
                }
        }
    }
}