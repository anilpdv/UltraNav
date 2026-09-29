# Task Lifecycle & Retention Management

## Principles
1. **Zero Unmanaged Tasks**: All asynchronous long-lived loops and consumers are registered with a `TaskRegistry`.
2. **Cancellation Propagation**: Whenever an engine or coordinator is shut down, reset, or deallocated, all associated tasks are deterministically cancelled.
3. **Weak Captures**: Background tasks looping over event streams capture `[weak self]` and test `guard !Task.isCancelled else { break }` on every iteration.
4. **Clean Deinitialization**: By delegating task retention to `TaskRegistry`, deinitializers remain free from nonisolated actor-isolation violations in Swift 6.
