import SwiftUI
import WatchKit

@main
struct UltraNavApp: App {
    @WKApplicationDelegateAdaptor(UltraNavApplicationDelegate.self)
    private var applicationDelegate

    @State private var container: AppContainer
    @State private var navigationModel = NavigationModel()

    init() {
        if NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            _container = State(initialValue: AppContainer.makePreview())
            return
        }
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
                .environment(container.presentation.app)
                .environment(container.presentation.ride)
                .environment(container.presentation.metrics)
                .environment(container.presentation.navigation)
                .environment(container.presentation.climb)
                .environment(container.presentation.routes)
                .environment(container.presentation.map)
                .environment(navigationModel)
                .task {
                    await container.start()
                }
        }
    }
}