import Foundation
@testable import UltraNav

@MainActor
final class MetricsSnapshotRecorder {
    private(set) var snapshots: [MetricsSnapshot] = []
    private var task: Task<Void, Never>?

    init(stream: AsyncStream<MetricsSnapshot>) {
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
