import Foundation

/// Thread-safe controlled stream wrapper allowing tests to inject items, control termination, and inspect subscriber counts.
final class ControlledAsyncStream<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncStream<Element>.Continuation?
    let stream: AsyncStream<Element>

    init(bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        var localContinuation: AsyncStream<Element>.Continuation?
        self.stream = AsyncStream(bufferingPolicy: bufferingPolicy) { cont in
            localContinuation = cont
        }
        self.continuation = localContinuation
    }

    /// Sends an item down the stream.
    func yield(_ element: Element) {
        lock.withLock {
            continuation?.yield(element)
        }
    }

    /// Finishes the stream cleanly.
    func finish() {
        lock.withLock {
            continuation?.finish()
            continuation = nil
        }
    }
}
