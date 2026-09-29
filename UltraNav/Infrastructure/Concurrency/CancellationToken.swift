import Foundation

/// A token that can be checked for cooperative cancellation across concurrency boundaries.
final class CancellationToken: @unchecked Sendable {
    private let isCancelledState = LockedValue(false)
    private let cancellationHandlers = LockedValue<[() -> Void]>([])

    init() {}

    /// Whether cancellation has been requested.
    var isCancelled: Bool {
        isCancelledState.get()
    }

    /// Triggers cancellation and notifies all registered handlers.
    func cancel() {
        let handlersToExecute: [() -> Void] = isCancelledState.withLock { isCancelled in
            guard !isCancelled else { return [] }
            isCancelled = true
            return cancellationHandlers.withLock { handlers in
                let list = handlers
                handlers.removeAll()
                return list
            }
        }
        for handler in handlersToExecute {
            handler()
        }
    }

    /// Registers a handler to be executed when cancellation occurs.
    func onCancel(_ handler: @escaping () -> Void) {
        let shouldExecuteImmediately = isCancelledState.withLock { isCancelled in
            if isCancelled {
                return true
            } else {
                cancellationHandlers.withLock { handlers in
                    handlers.append(handler)
                }
                return false
            }
        }
        if shouldExecuteImmediately {
            handler()
        }
    }
}
