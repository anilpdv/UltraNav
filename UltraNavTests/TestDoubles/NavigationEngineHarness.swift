import Foundation
@testable import UltraNav

@MainActor
final class NavigationEngineHarness {
    let routeMatcher: FakeRouteMatcher
    let cueProvider: FakeCueProvider
    let cueProgressor: FakeCueProgressor
    let offRouteEvaluator: FakeOffRouteEvaluator
    let completionEvaluator: FakeRouteCompletionEvaluator
    let engine: NavigationEngine

    let snapshotRecorder: NavigationSnapshotRecorder
    let notificationRecorder: NavigationNotificationRecorder

    init(
        routeMatcher: FakeRouteMatcher = FakeRouteMatcher(),
        cueProvider: FakeCueProvider = FakeCueProvider(),
        cueProgressor: FakeCueProgressor = FakeCueProgressor(),
        offRouteEvaluator: FakeOffRouteEvaluator = FakeOffRouteEvaluator(),
        completionEvaluator: FakeRouteCompletionEvaluator = FakeRouteCompletionEvaluator()
    ) {
        self.routeMatcher = routeMatcher
        self.cueProvider = cueProvider
        self.cueProgressor = cueProgressor
        self.offRouteEvaluator = offRouteEvaluator
        self.completionEvaluator = completionEvaluator

        let engine = NavigationEngine(
            routeMatcher: routeMatcher,
            cueProvider: cueProvider,
            cueProgressor: cueProgressor,
            offRouteEvaluator: offRouteEvaluator,
            completionEvaluator: completionEvaluator
        )
        self.engine = engine

        self.snapshotRecorder = NavigationSnapshotRecorder(
            stream: engine.snapshots,
            initialSnapshot: engine.currentSnapshot
        )
        self.notificationRecorder = NavigationNotificationRecorder(
            stream: engine.notifications
        )
    }
}
