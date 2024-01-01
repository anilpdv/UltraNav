import SwiftUI
import WatchKit

@main
struct UltraNavApp: App {
    @WKApplicationDelegateAdaptor(UltraNavApplicationDelegate.self)
    private var applicationDelegate

    @State private var navigationModel = NavigationModel()
    @State private var cyclingEngine = CyclingRideEngine.shared

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
                .environment(navigationModel)
                .environment(cyclingEngine)
        }
    }
}