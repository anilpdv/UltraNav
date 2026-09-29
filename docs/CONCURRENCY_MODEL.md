# Concurrency Model

## Overview
UltraNav employs a single-isolation domain architecture grounded in Swift 6 concurrency principles.

## Isolation Boundaries
```
System / Framework Callbacks (CoreLocation, HealthKit, CoreBluetooth)
              │
              ▼
  Actor-Isolated / Locked Delegate Bridges
              │
              ▼
  Sendable Domain Events (LocationServiceEvent, WorkoutServiceEvent, SensorServiceEvent)
              │
              ▼
  @MainActor Coordinators & Engines (RideLifecycleCoordinator, RideEngine, etc.)
              │
              ▼
  Immutable Sendable Snapshots (RideSnapshot, MetricsSnapshot, NavigationSnapshot, ClimbSnapshot)
              │
              ▼
  @MainActor ViewModels & SwiftUI Presentation Layer
```

## Concurrency Components
1. **`LockedValue<T>`**: High-performance thread-safe wrapper around `os_unfair_lock` for critical sections.
2. **`AsyncEventChannel<Element>`**: Thread-safe event distribution channel supporting multiple concurrent subscribers with custom backpressure/buffering policies.
3. **`EventStreamOwner<Element>`**: Single-owner AsyncStream lifecycle controller with completion safety.
4. **`TaskRegistry`**: Centralized storage for background tasks ensuring proper cancellation without memory leaks or retain cycles.
5. **`CancellationToken`**: Cooperative cancellation across asynchronous boundaries.
6. **`TickProviding` / `SystemTicker` / `ManualTicker`**: Concurrency-safe timer and tick generation without legacy `Timer` retain cycles.
