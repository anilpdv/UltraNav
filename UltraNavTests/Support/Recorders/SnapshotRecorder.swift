import Foundation

/// Generic thread-safe actor that records snapshots emitted from engine streams.
actor SnapshotRecorder<Snapshot: Equatable & Sendable> {
    private(set) var snapshots: [Snapshot] = []

    func record(_ snapshot: Snapshot) {
        snapshots.append(snapshot)
    }

    var latest: Snapshot? {
        snapshots.last
    }

    var count: Int {
        snapshots.count
    }

    var all: [Snapshot] {
        snapshots
    }

    func clear() {
        snapshots.removeAll()
    }
}

/// Helper to consume snapshots from an AsyncStream into a SnapshotRecorder.
func recordSnapshots<Snapshot: Equatable & Sendable>(
    from stream: AsyncStream<Snapshot>,
    into recorder: SnapshotRecorder<Snapshot>
) -> Task<Void, Never> {
    Task {
        for await snapshot in stream {
            guard !Task.isCancelled else { break }
            await recorder.record(snapshot)
        }
    }
}
