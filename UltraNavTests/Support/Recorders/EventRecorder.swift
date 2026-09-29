import Foundation

/// Generic actor recording events emitted across test streams and coordinators.
actor EventRecorder<Event: Equatable & Sendable> {
    private(set) var events: [Event] = []

    func record(_ event: Event) {
        events.append(event)
    }

    var count: Int {
        events.count
    }

    var latest: Event? {
        events.last
    }

    var all: [Event] {
        events
    }

    func clear() {
        events.removeAll()
    }
}

/// Helper to consume events from an AsyncStream into an EventRecorder.
func recordEvents<Event: Equatable & Sendable>(
    from stream: AsyncStream<Event>,
    into recorder: EventRecorder<Event>
) -> Task<Void, Never> {
    Task {
        for await event in stream {
            guard !Task.isCancelled else { break }
            await recorder.record(event)
        }
    }
}
