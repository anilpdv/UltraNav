import Foundation

/// A thread-safe, multi-subscriber asynchronous event channel.
final class AsyncEventChannel<Element: Sendable>: @unchecked Sendable {
    typealias BufferingPolicy = AsyncStream<Element>.Continuation.BufferingPolicy

    private struct State {
        var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
        var isFinished: Bool = false
    }

    private let state = LockedValue(State())
    private let bufferingPolicy: BufferingPolicy

    init(bufferingPolicy: BufferingPolicy = .unbounded) {
        self.bufferingPolicy = bufferingPolicy
    }

    /// Creates a new `AsyncStream` subscriber to this event channel.
    func makeStream() -> AsyncStream<Element> {
        let isFin = state.withLock { $0.isFinished }
        if isFin {
            return AsyncStream(Element.self) { continuation in
                continuation.finish()
            }
        }

        let id = UUID()
        return AsyncStream(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
            state.withLock { inner in
                if inner.isFinished {
                    continuation.finish()
                } else {
                    inner.continuations[id] = continuation
                }
            }

            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { inner in
                    inner.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    /// Broadcasts an element to all active subscribers.
    func send(_ element: Element) {
        let activeContinuations: [AsyncStream<Element>.Continuation] = state.withLock { s in
            guard !s.isFinished else { return [] }
            return Array(s.continuations.values)
        }

        for continuation in activeContinuations {
            continuation.yield(element)
        }
    }

    /// Finishes all subscriber streams and closes the channel.
    func finish() {
        let toFinish: [AsyncStream<Element>.Continuation] = state.withLock { s in
            guard !s.isFinished else { return [] }
            s.isFinished = true
            let list = Array(s.continuations.values)
            s.continuations.removeAll()
            return list
        }

        for continuation in toFinish {
            continuation.finish()
        }
    }

    /// Number of active subscriber streams.
    var subscriberCount: Int {
        state.withLock { $0.continuations.count }
    }

    /// Whether the channel is finished.
    var isFinished: Bool {
        state.withLock { $0.isFinished }
    }
}
