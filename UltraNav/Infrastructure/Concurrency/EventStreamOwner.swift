import Foundation

/// Manages an `AsyncStream<Element>` and its underlying continuation safely.
final class EventStreamOwner<Element: Sendable>: @unchecked Sendable {
    typealias BufferingPolicy = AsyncStream<Element>.Continuation.BufferingPolicy

    private struct State {
        var continuation: AsyncStream<Element>.Continuation?
        var isFinished: Bool = false
    }

    private let state = LockedValue(State())
    let stream: AsyncStream<Element>

    init(bufferingPolicy: BufferingPolicy = .unbounded) {
        var localContinuation: AsyncStream<Element>.Continuation?
        self.stream = AsyncStream(Element.self, bufferingPolicy: bufferingPolicy) { cont in
            localContinuation = cont
        }

        if let cont = localContinuation {
            state.withLock { s in
                s.continuation = cont
            }
            cont.onTermination = { [weak self] _ in
                self?.state.withLock { s in
                    s.continuation = nil
                    s.isFinished = true
                }
            }
        }
    }

    /// Yields an element to the stream. Returns the yield result if active.
    @discardableResult
    func yield(_ value: Element) -> AsyncStream<Element>.Continuation.YieldResult? {
        state.withLock { s in
            guard !s.isFinished, let continuation = s.continuation else { return nil }
            return continuation.yield(value)
        }
    }

    /// Finishes the stream continuation.
    func finish() {
        let continuation = state.withLock { s -> AsyncStream<Element>.Continuation? in
            guard !s.isFinished else { return nil }
            s.isFinished = true
            let c = s.continuation
            s.continuation = nil
            return c
        }
        continuation?.finish()
    }

    /// Indicates whether the stream has terminated or finished.
    var isFinished: Bool {
        state.withLock { $0.isFinished }
    }
}
