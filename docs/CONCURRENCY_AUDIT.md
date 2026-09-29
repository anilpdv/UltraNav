# Concurrency Audit

## Subsystem Audit Summary

| Component | Isolation | Mutable State | Long-Lived Tasks | Sendable Inputs | Concurrency Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RideEngine** | `@MainActor` | StateMachine, TimingState, MetricState | Managed via `TaskRegistry` | Commands, Samples, Events | `AsyncEventChannel` + `TaskRegistry` |
| **MetricsEngine** | `@MainActor` | State, MetricStore | None | `MetricsInput`, Commands | `AsyncEventChannel` |
| **NavigationEngine** | `@MainActor` | StateMachine, RouteState, ProgressState | None | `LocationSample`, Commands | `AsyncEventChannel` (snapshots & notifications) |
| **ClimbEngine** | `@MainActor` | ElevationProfile, Climbs, Progress | None | `LocationSample`, `NavigationSnapshot` | `AsyncEventChannel` (snapshots & notifications) |
| **RideLifecycleCoordinator**| `@MainActor` | Command in progress | Delegated to engines | Lifecycle commands | `@MainActor` method serialization |
| **LocationService** | `@MainActor` | State | CoreLocation delegate | Location config | `AsyncStream` / Bridge |
| **HealthKitService** | `@MainActor` | State, Session, Builder | HKLiveWorkoutBuilder | Workout config | `AsyncStream` / Bridge |
| **BluetoothService** | `@MainActor` | ScanState, Contexts | CBCentralManager | Scan requests | `AsyncStream` / Bridge |
| **ViewModels** | `@MainActor` | Immutable ViewStates | `@Observable` observation tasks | Domain snapshots | MainActor async loops |
