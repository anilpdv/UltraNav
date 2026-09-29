import Foundation
@testable import UltraNav

@MainActor
final class NavigationSnapshotRecorder {
    private(set) var snapshots: [NavigationSnapshot] = []
    private var task: Task<Void, Never>?

    init(stream: AsyncStream<NavigationSnapshot>, initialSnapshot: NavigationSnapshot? = nil) {
        if let initialSnapshot {
            snapshots.append(initialSnapshot)
        }
        task = Task { [weak self] in
            for await snapshot in stream {
                guard !Task.isCancelled else { break }
                self?.snapshots.append(snapshot)
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
