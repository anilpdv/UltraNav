import Combine
import Foundation
import WatchKit

@MainActor
final class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()

    @Published private(set) var nextScheduledRefresh: Date?
    @Published private(set) var lastSchedulingError: String?

    private let enabledKey = "backgroundRefreshEnabled"
    private let minimumInterval: TimeInterval = 60 * 60

    private init() {}

    func scheduleNextRefresh(
        earliest date: Date? = nil
    ) {
        guard UserDefaults.standard.object(forKey: enabledKey) == nil
                || UserDefaults.standard.bool(forKey: enabledKey) else {
            nextScheduledRefresh = nil
            lastSchedulingError = nil
            AppLogger.lifecycle.info("Background refresh is disabled")
            return
        }

        let preferredDate = max(
            date ?? Date().addingTimeInterval(minimumInterval),
            Date().addingTimeInterval(minimumInterval)
        )

        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: preferredDate,
            userInfo: nil
        ) { [weak self] error in
            Task { @MainActor in
                if let error {
                    AppLogger.lifecycle.error("Background refresh scheduling failed: \(String(describing: type(of: error)), privacy: .public)")
                    self?.lastSchedulingError = error.localizedDescription
                    self?.nextScheduledRefresh = nil
                } else {
                    AppLogger.lifecycle.info("Background refresh scheduled")
                    self?.lastSchedulingError = nil
                    self?.nextScheduledRefresh = preferredDate
                }
            }
        }
    }

    func handle(_ tasks: Set<WKRefreshBackgroundTask>) {
        for task in tasks {
            if let applicationTask = task as? WKApplicationRefreshBackgroundTask {
                Task {
                    await NotificationManager.shared.refreshPermissionStatus()
                    scheduleNextRefresh()
                    applicationTask.setTaskCompletedWithSnapshot(false)
                }
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

final class UltraNavApplicationDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        AppLogger.lifecycle.info("Application finished launching")
        Task { @MainActor in
            NotificationManager.shared.registerCategories()
            BackgroundRefreshManager.shared.scheduleNextRefresh()
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        Task { @MainActor in
            BackgroundRefreshManager.shared.handle(backgroundTasks)
        }
    }
}
