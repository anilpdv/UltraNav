# UltraNav Implementation Status & Roadmap

**Current Phase:** Phase 1J (MetricsEngine Boundary) — **COMPLETED**

---

## Phase 1 Acceptance Checklist

### Domain Models (Phase 1B)
- [x] Framework-independent `Coordinate` and `LocationSample` models exist.
- [x] Immutable `RideSnapshot` and `NavigationSnapshot` models exist.
- [x] Pure metrics and climb models (`RideMetrics`, `ClimbSnapshot`).
- [x] Domain models have strict `Sendable` value semantics without framework leaks.

### Explicit State Machines (Phase 1C)
- [x] Explicit `RideState` state machine (`idle`, `preparing`, `ready`, `starting`, `active`, `pausing`, `paused`, `resuming`, `finishing`, `completed`, `failed(failure, recovery)`).
- [x] Explicit `NavigationState` state machine (`inactive`, `loading`, `ready`, `starting`, `navigating`, `suspectedOffRoute`, `offRoute`, `rejoining`, `finishing`, `finished`, `failed(failure, recovery)`).
- [x] Domain-oriented `RideEffect` and `NavigationEffect` commands.
- [x] Pure value-type state machine implementations (`RideStateMachine`, `NavigationStateMachine`).
- [x] Strict transition tables with typed rejection errors (`RideTransitionError`, `NavigationTransitionError`).
- [x] State preservation invariant on rejected transitions.
- [x] 100% test coverage for lifecycle paths, failures, and recovery.

### Service Protocol Boundaries (Phase 1D)
- [x] Framework-independent `LocationProviding` protocol decoupling CoreLocation.
- [x] Framework-independent `WorkoutProviding` protocol decoupling HealthKit.
- [x] Framework-independent `SensorProviding` protocol decoupling CoreBluetooth.
- [x] Framework-independent `RouteStoring` protocol decoupling filesystem & persistence.
- [x] Framework-independent `RidePersisting` protocol decoupling ride storage.
- [x] Framework-independent `ClockProviding` and `SleepProviding` decoupling system clocks.
- [x] Framework-independent `HapticProviding` decoupling WatchKit haptics.
- [x] Pure asynchronous event streams (`AsyncStream`) for all streaming boundaries.
- [x] Zero framework leaks (`CLLocation`, `HKWorkoutSession`, `CBPeripheral`) in boundary APIs.
- [x] Zero raw OS error leaks (`NSError`, `CLError`, `HKError`, `CBError`) in failure models.
- [x] Actor-backed test doubles (`FakeLocationProvider`, `FakeWorkoutProvider`, `FakeSensorProvider`, `FakeRouteStore`, `FakeRidePersistence`, `TestClock`).
- [x] 100% contract verification test suite for all test doubles and storage providers.

### Core Location Service Boundary (Phase 1E)
- [x] `CoreLocationSampleConverter` for structural raw `CLLocation` to `LocationSample` domain conversion.
- [x] `CoreLocationDelegateBridge` decoupling `CLLocationManagerDelegate` callbacks.
- [x] `CoreLocationManaging` protocol abstraction allowing test double injection (`FakeLocationManager`).
- [x] `LocationConfiguration` centralized settings presets (`desiredAccuracy`, `distanceFilter`, `allowsBackgroundLocationUpdates`).
- [x] `LocationServiceState` internal lifecycle management.
- [x] Idempotent start and stop commands with bounded event stream (`bufferingNewest(10)`).
- [x] 100% unit test coverage for converter, authorization mapping, configuration, lifecycle, and transient error recovery.

### HealthKit Service Boundary (Phase 1F)
- [x] `WorkoutConfiguration` for outdoor cycling configuration mapping.
- [x] `HealthKitDataTypes` explicit read and share type sets.
- [x] `HealthKitAuthorizing` and `HealthKitAuthorizationClient` isolating authorization.
- [x] `HealthKitWorkoutFactory` for `HKWorkoutSession` and `HKLiveWorkoutBuilder` creation.
- [x] `HealthKitSessionManaging` and `HealthKitBuilderManaging` protocols with adapters.
- [x] `HealthKitDelegateBridge` decoupling session and builder delegates.
- [x] `HealthKitMetricConverter` normalizing `HKStatistics` to `WorkoutMetric`.
- [x] `HealthKitService` managing workout lifecycle, bounded events (`bufferingNewest(50)`), and finalization.
- [x] 100% unit test coverage for authorization, configuration, preparation, lifecycle, finalization, and failure paths.

### Bluetooth Service Boundary (Phase 1G)
- [x] `BluetoothAvailability` capturing fine-grained CoreBluetooth manager availability.
- [x] `SensorScanRequest` and `SensorScanState` formalizing scan parameters and lifecycle.
- [x] `CoreBluetoothUUIDs` and `SensorServiceDefinition` centralizing cycling GATT service specifications.
- [x] `CoreBluetoothManaging` and `CoreBluetoothPeripheralManaging` protocol abstractions.
- [x] `CoreBluetoothDelegateBridge` and `PeripheralDelegateBridge` serializing delegate callbacks to `@MainActor`.
- [x] `SensorMeasurementPacket` decoupling raw characteristic byte streams from parsers.
- [x] `SensorPacketParsing` protocol with legacy adapters (`LegacyHeartRateParserAdapter`, `LegacyCyclingPowerParserAdapter`, `LegacyCSCParserAdapter`, `CyclingSensorPacketParser`).
- [x] `PeripheralContext` and `BluetoothService` managing scanning, discovery, connections, discovery pipeline, subscription confirmation, packet routing, and disconnection handling.
- [x] Bounded event stream (`bufferingNewest(100)`).
- [x] 100% unit test coverage for mapper, availability, scanning, discovery, connections, subscriptions, and failure handling.

### RideEngine Extraction (Phase 1H)
- [x] `RideEngine` coordinates ride lifecycle through pure `RideStateMachine`.
- [x] Hardware coordination via `LocationProviding`, `WorkoutProviding`, and `SensorProviding`.
- [x] Bounded publication stream (`AsyncStream<RideSnapshot>`).
- [x] Degradation tracking (`RideDegradation`).
- [x] `LegacyRideEngineAdapter` and `CyclingRideEngine` bridging.
- [x] 100% unit test coverage across lifecycle, timings, failures, and event consumption.

### NavigationEngine Boundary (Phase 1I)
- [x] `NavigationEngine` coordinates navigation lifecycle through pure `NavigationStateMachine`.
- [x] Route loading, validation, matching, cue progression, and off-route detection interfaces.
- [x] Bounded publication streams (`AsyncStream<NavigationSnapshot>` and `AsyncStream<NavigationNotification>`).
- [x] `RideNavigationCoordinator` fan-out and lifecycle synchronization.
- [x] 100% unit test coverage across route loading, lifecycle, locations, cues, off-route transitions, and integration.

### MetricsEngine Boundary (Phase 1J)
- [x] `MetricsEngine` coordinates measurement ingestion, provenance, and freshness.
- [x] Strongly typed `MetricObservation`, `MetricSource`, and `MetricValue` domain models.
- [x] In-memory sliding buffer (`RollingSampleBuffer`) and `MetricStore`.
- [x] `StandardMetricValidator` for sanity checking measurements.
- [x] Rolling average and maximum calculation (`AverageCalculating`, `MaximumCalculating`).
- [x] `LegacyMetricsAdapter` for view projection.
- [x] 100% unit test coverage across lifecycle, location/workout/sensor ingestion, freshness aging, aggregations, source tracking, and resets.

### ClimbEngine Boundary (Phase 1K)
- [x] `ClimbEngine` coordinates elevation profile parsing, climb detection, classification, active climb tracking, and live progress.
- [x] Strongly typed `Climb`, `ClimbCategory`, `ClimbGradientSlice`, `ClimbStatus`, and `ClimbProgress` domain models.
- [x] Background actor isolation (`ClimbAnalysisService`) for off-main-thread profile parsing and candidate scanning.
- [x] Monotonic climb completion tracking (`ActiveClimbSelecting`, `StandardActiveClimbSelector`).
- [x] Dynamic climb progress calculation (`ClimbProgressCalculating`, `StandardClimbProgressCalculator`).
- [x] Bounded publication streams (`AsyncStream<ClimbSnapshot>` and `AsyncStream<ClimbNotification>`).
- [x] `LegacyClimbAdapter` and `CyclingRideEngine` bridging.
- [x] 100% unit test coverage across lifecycle, route analysis, active climb selection, live progress calculation, completions/skips, failures, resets, and end-to-end integration.

### Route and GPX Boundary (Phase 1L)
- [x] Strongly typed `Route`, `RouteMetadata`, `RoutePoint`, and `RouteSummary` domain models.
- [x] `GPXParserAdapter` isolating legacy XML parser behind `GPXParsing`.
- [x] `ParsedRouteValidator` and `StoredRouteValidator` ensuring route geometric integrity.
- [x] `RouteNormalizer` filtering duplicate points and calculating cumulative distances.
- [x] `RouteImporter` coordinating validation and normalization pipeline.
- [x] File-backed `RouteStore` with atomic JSON writes, index corruption recovery, and active route deletion protection.
- [x] `RouteLibraryEngine` managing in-memory route catalog state, selection, and deletion.
- [x] `LegacyRouteLibraryAdapter` bridging SwiftUI views to `RouteLibraryEngine`.
- [x] 100% unit test coverage across parser adapters, validation, normalization, storage recovery, and library engine.

### Dependency Injection & AppContainer (Phase 1M)
- [x] Single explicit composition root (`AppContainer`) managing app-wide dependency lifecycles.
- [x] Platform infrastructure wrappers (`SystemClock`, `WatchHapticService`, `LocalRouteFileSystem`).
- [x] Pure configuration tree (`AppConfiguration`, `AppEnvironment`).
- [x] Stream consumer fan-out coordinator (`RideDataCoordinator`).
- [x] Synchronized timestamped lifecycle coordinator (`RideLifecycleCoordinator`).
- [x] Safe route-loading and progress forwarding coordinator (`RouteNavigationCoordinator`).
- [x] Haptic feedback notification coordinator (`NavigationNotificationCoordinator`).
- [x] Unified coordinator root (`AppCoordinator`).
- [x] Consolidated presentation container (`AppPresentationContainer`).
- [x] Deterministic preview container (`PreviewAppContainer.makePreview()`).
- [x] Zero singletons or direct framework allocations in views.
- [x] 100% unit test coverage across container creation, lifetime transitions, startup/shutdown, and all coordinators.

---

## Upcoming Phases Roadmap

| Phase | Milestone Name | Objective | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1A** | **Architecture Audit & Inventory** | Inventory boundaries, state, and dependencies. | **COMPLETED** |
| **Phase 1B** | **Domain Model Foundation** | Framework-independent models and geometry. | **COMPLETED** |
| **Phase 1C** | **Explicit State Machines** | Deterministic lifecycle state machines and effects. | **COMPLETED** |
| **Phase 1D** | **Service Protocol Boundaries** | Formalize hardware protocols & event streams. | **COMPLETED** |
| **Phase 1E** | **Core Location Service Boundary** | Isolate CoreLocation behind LocationProviding. | **COMPLETED** |
| **Phase 1F** | **HealthKit Service Boundary** | Isolate HealthKit behind WorkoutProviding. | **COMPLETED** |
| **Phase 1G** | **Bluetooth Service Boundary** | Isolate CoreBluetooth behind SensorProviding. | **COMPLETED** |
| **Phase 1H** | **RideEngine Extraction** | Unify Location, Workout, and Sensor into RideEngine. | **COMPLETED** |
| **Phase 1I** | **NavigationEngine Boundary** | Isolate navigation lifecycle, route matching, cues. | **COMPLETED** |
| **Phase 1J** | **MetricsEngine Boundary** | Isolate metric ingestion, provenance, freshness. | **COMPLETED** |
| **Phase 1K** | **ClimbEngine Boundary** | Isolate climb analysis, grade calculation, and segments. | **COMPLETED** |
| **Phase 1L** | **Route and GPX Boundary** | Isolate route import, parsing, validation, normalization, and storage. | **COMPLETED** |
| **Phase 1M** | **Dependency Injection & AppContainer** | Single composition root and DI unification. | **COMPLETED** |
| **Phase 2** | **GPX Engine & Ingestion** | Robust XML streaming, waypoint normalization, route compression. | Pending |
| **Phase 3** | **Location & Sensor Fusion** | Kalman GPS filtering, barometric altitude fusion, auto-pause hysteresis. | Pending |


