import Foundation
import Testing
@testable import UltraNav

@Suite("TaskRegistry Lifecycle Tests")
struct TaskRegistryTests {
    @Test("Replacing a task cancels the previous task")
    func testReplacingTaskCancelsPrevious() async {
        let registry = TaskRegistry()
        let cancelled = LockedValue(false)

        let task1 = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            cancelled.set(true)
        }

        registry.store(task1, forKey: "key1")
        #expect(registry.contains(key: "key1"))
        #expect(registry.count == 1)

        let task2 = Task {
            _ = try? await Task.sleep(nanoseconds: 10_000_000)
        }
        registry.store(task2, forKey: "key1")

        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(cancelled.get())
        #expect(registry.count == 1)

        registry.cancelAll()
    }

    @Test("Cancel all cancels every active task")
    func testCancelAllCancelsEveryTask() async {
        let registry = TaskRegistry()
        let count = LockedValue(0)

        for i in 0..<5 {
            let task = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                count.withLock { $0 += 1 }
            }
            registry.store(task, forKey: "task_\(i)")
        }

        #expect(registry.count == 5)
        registry.cancelAll()

        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(registry.count == 0)
        #expect(count.get() == 5)
    }
}
