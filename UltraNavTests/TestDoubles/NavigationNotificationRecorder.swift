import Foundation
@testable import UltraNav

@MainActor
final class NavigationNotificationRecorder {
    private(set) var notifications: [NavigationNotification] = []
    private var task: Task<Void, Never>?

    init(stream: AsyncStream<NavigationNotification>) {
        task = Task { [weak self] in
            for await notification in stream {
                guard !Task.isCancelled else { break }
                self?.notifications.append(notification)
            }
        }
    }

    deinit {
        task?.cancel()
    }

    func cancel() {
        task?.cancel()
    }
}
