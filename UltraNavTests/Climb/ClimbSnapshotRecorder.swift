import Foundation
@testable import UltraNav

@MainActor
final class ClimbSnapshotRecorder {
    private(set) var snapshots: [ClimbSnapshot] = []
    private var task: Task<Void, Never>?

    func startRecording(stream: AsyncStream<ClimbSnapshot>) {
        task = Task { @MainActor [weak self] in
            for await snap in stream {
                self?.snapshots.append(snap)
            }
        }
    }

    func stopRecording() {
        task?.cancel()
        task = nil
    }
}

@MainActor
final class ClimbNotificationRecorder {
    private(set) var notifications: [ClimbNotification] = []
    private var task: Task<Void, Never>?

    func startRecording(stream: AsyncStream<ClimbNotification>) {
        task = Task { @MainActor [weak self] in
            for await note in stream {
                self?.notifications.append(note)
            }
        }
    }

    func stopRecording() {
        task?.cancel()
        task = nil
    }
}
