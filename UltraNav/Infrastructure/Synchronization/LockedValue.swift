import Foundation
import os

/// Thread-safe locked wrapper around a value using `os_unfair_lock`.
final class LockedValue<Value>: @unchecked Sendable {
    private var lock = os_unfair_lock_s()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    /// Accesses or modifies the wrapped value synchronously inside a lock.
    @discardableResult
    func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return try body(&value)
    }

    /// Gets a copy of the current value.
    func get() -> Value {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return value
    }

    /// Sets the value to a new value.
    func set(_ newValue: Value) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        value = newValue
    }

    /// Swaps the current value with a new one, returning the previous value.
    func swap(_ newValue: Value) -> Value {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        let previous = value
        value = newValue
        return previous
    }
}
