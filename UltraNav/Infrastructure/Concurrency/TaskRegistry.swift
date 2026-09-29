import Foundation

/// A thread-safe registry for managing the lifecycle of background and long-lived asynchronous tasks.
final class TaskRegistry: @unchecked Sendable {
    private let tasks = LockedValue<[String: Task<Void, Never>]>([:])

    init() {}

    deinit {
        cancelAll()
    }

    /// Stores a task under a specific identifier, cancelling any existing task with that identifier.
    func store(_ task: Task<Void, Never>, forKey key: String) {
        let previous = tasks.withLock { dict in
            let old = dict[key]
            dict[key] = task
            return old
        }
        previous?.cancel()
    }

    /// Cancels and removes a task by key.
    func cancel(forKey key: String) {
        let task = tasks.withLock { dict in
            dict.removeValue(forKey: key)
        }
        task?.cancel()
    }

    /// Cancels all registered tasks and clears the registry.
    func cancelAll() {
        let allTasks = tasks.withLock { dict -> [Task<Void, Never>] in
            let current = Array(dict.values)
            dict.removeAll()
            return current
        }
        for task in allTasks {
            task.cancel()
        }
    }

    /// Checks if a task with the given key is currently registered.
    func contains(key: String) -> Bool {
        tasks.withLock { $0[key] != nil }
    }

    /// Number of active registered tasks.
    var count: Int {
        tasks.withLock { $0.count }
    }
}
