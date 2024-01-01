import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    enum Category {
        static let navigationReminder = "NAVIGATION_REMINDER"
    }

    enum Action {
        static let openNavigation = "OPEN_NAVIGATION"
        static let dismiss = "DISMISS_NAVIGATION_REMINDER"
    }

    enum PermissionStatus: Equatable {
        case notDetermined
        case denied
        case authorised
        case provisional
        case ephemeral
        case unknown

        var title: String {
            switch self {
            case .notDetermined: return "Not requested"
            case .denied: return "Denied"
            case .authorised: return "Allowed"
            case .provisional: return "Provisional"
            case .ephemeral: return "Temporary"
            case .unknown: return "Unknown"
            }
        }

        var notificationsAvailable: Bool {
            switch self {
            case .authorised, .provisional, .ephemeral:
                return true
            case .notDetermined, .denied, .unknown:
                return false
            }
        }
    }

    static let deepLinkNotification = Notification.Name("UltraNavDeepLinkRequested")

    @Published private(set) var permissionStatus: PermissionStatus = .notDetermined

    private let notificationCenter: UNUserNotificationCenter

    private override init() {
        notificationCenter = .current()
        super.init()
        notificationCenter.delegate = self
        registerCategories()

        Task {
            await refreshPermissionStatus()
        }
    }

    func registerCategories() {
        let openAction = UNNotificationAction(
            identifier: Action.openNavigation,
            title: "Open route",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: Action.dismiss,
            title: "Dismiss",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Category.navigationReminder,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
        AppLogger.notifications.info("Registered navigation notification category")
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )
            await refreshPermissionStatus()
            AppLogger.notifications.info(
                "Notification authorisation request completed; granted: \(granted, privacy: .public)"
            )
            return granted
        } catch {
            AppLogger.notifications.error(
                "Notification authorisation request failed: \(String(describing: Swift.type(of: error)), privacy: .public)"
            )
            await refreshPermissionStatus()
            return false
        }
    }

    func refreshPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        permissionStatus = Self.map(settings.authorizationStatus)
    }

    static func reminderDescriptor(
        identifier: String,
        title: String,
        body: String,
        at date: Date,
        now: Date = .now
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Category.navigationReminder
        content.userInfo = ["deepLink": "ultranav://navigation"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(date.timeIntervalSince(now), 1),
            repeats: false
        )
        return UNNotificationRequest(
            identifier: "navigation-reminder.\(identifier)",
            content: content,
            trigger: trigger
        )
    }

    func scheduleNavigationReminder(
        identifier: String,
        title: String,
        body: String,
        at date: Date
    ) async throws {
        await refreshPermissionStatus()
        guard permissionStatus.notificationsAvailable else {
            throw NotificationError.permissionUnavailable
        }

        let request = Self.reminderDescriptor(
            identifier: identifier,
            title: title,
            body: body,
            at: date
        )
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [request.identifier]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [request.identifier]
        )

        do {
            try await notificationCenter.add(request)
            AppLogger.notifications.info("Scheduled navigation reminder")
        } catch {
            AppLogger.notifications.error(
                "Failed to schedule navigation reminder: \(String(describing: Swift.type(of: error)), privacy: .public)"
            )
            throw error
        }
    }

    func cancelNavigationReminder(identifier: String) {
        let requestIdentifier = "navigation-reminder.\(identifier)"
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [requestIdentifier]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [requestIdentifier]
        )
        AppLogger.notifications.info("Cancelled navigation reminder")
    }

    private static func map(
        _ status: UNAuthorizationStatus
    ) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorised
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .unknown
        }
    }

    enum NotificationError: LocalizedError {
        case permissionUnavailable

        var errorDescription: String? {
            "Notifications are not allowed. Update notification permission in Settings."
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier
                || response.actionIdentifier == Action.openNavigation else {
            return
        }

        let rawURL = response.notification.request.content.userInfo["deepLink"] as? String
        guard let rawURL, let url = URL(string: rawURL) else {
            return
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: Self.deepLinkNotification,
                object: url
            )
        }
    }
}