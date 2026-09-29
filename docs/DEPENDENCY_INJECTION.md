# UltraNav Dependency Injection Architecture

## 1. Composition Root Pattern
UltraNav employs a single, explicit composition root encapsulated within `AppContainer`. Rather than using service locators, global singletons, or runtime reflection injection, all dependencies are constructed hierarchically at application startup and passed down through constructor injection.

```
                  ┌──────────────────────┐
                  │     AppContainer     │
                  │  (Composition Root)  │
                  └──────────┬───────────┘
                             │
     ┌───────────────────────┼────────────────────────┐
     ▼                       ▼                        ▼
Infrastructure            Services                 Engines
- ClockProviding          - LocationProviding      - RideEngineProviding
- HapticProviding         - WorkoutProviding       - NavigationEngineProviding
- RouteFileSystem         - SensorProviding        - MetricsEngineProviding
                          - RouteStoring           - ClimbEngineProviding
                                                   - RouteLibraryProviding
                             │
                             ▼
                        Coordinators
               - RideDataCoordinator
               - RideLifecycleCoordinator
               - RouteNavigationCoordinator
               - NavigationNotificationCoordinator
               - AppCoordinator
                             │
                             ▼
                   Presentation Adapters
               - LegacyRideEngineAdapter
               - LegacyNavigationAdapter
               - LegacyMetricsAdapter
               - LegacyClimbAdapter
               - LegacyRouteLibraryAdapter
```

---

## 2. Dependency Graph & Layers

1. **Infrastructure Layer**:
   - `SystemClock`: System time provider conforming to `ClockProviding`.
   - `WatchHapticService`: Hardware haptic player using `WKInterfaceDevice` conforming to `HapticProviding`.
   - `LocalRouteFileSystem`: Sandboxed filesystem operations for route storage conforming to `RouteFileSystemProviding`.

2. **Platform Services Layer**:
   - `LocationService`: Isolates CoreLocation and CLLocationManager behind `LocationProviding`.
   - `HealthKitService`: Isolates HealthKit workout sessions and builders behind `WorkoutProviding`.
   - `BluetoothService`: Isolates CoreBluetooth CBCentralManager behind `SensorProviding`.
   - `RouteStore`: File-backed route persistence behind `RouteStoring`.

3. **Domain Engines Layer**:
   - `RideEngine`: Ride lifecycle state and timing coordination.
   - `NavigationEngine`: Route point matching, navigation state machine, and cue progression.
   - `MetricsEngine`: Multi-source telemetry aggregation, rolling metrics, and freshness tracking.
   - `ClimbEngine`: Climb detection, categorization, and active climb progress tracking.
   - `RouteLibraryEngine`: Route import, indexing, selection, and deletion.

4. **Coordination Layer**:
   - `RideDataCoordinator`: Single consumer of sensor streams (`Location`, `Workout`, `Bluetooth`), fanning out immutable domain events to `RideEngine`, `MetricsEngine`, and `NavigationEngine`.
   - `RideLifecycleCoordinator`: Synchronizes lifecycle commands (`prepare`, `start`, `pause`, `resume`, `finish`, `reset`) with consistent timestamps across all active engines.
   - `RouteNavigationCoordinator`: Manages canonical route loading across `RouteLibraryEngine`, `NavigationEngine`, and `ClimbEngine`, preventing stale generational overwrites and protecting active route deletion.
   - `NavigationNotificationCoordinator`: Translates navigation cues, off-route warnings, and climb transitions into haptic playback patterns.
   - `AppCoordinator`: Unified facade coordinating startup, backgrounding, and shutdown of all sub-coordinators.

5. **Presentation Layer**:
   - `AppPresentationContainer`: Projections over engine snapshot streams consumed by SwiftUI views without direct access to hardware or platform services.

---

## 3. Container Variations

- **`AppContainer.makeProduction()`**:
  - Initializes real platform services (CoreLocation, HealthKit, CoreBluetooth, WatchKit haptics, sandboxed filesystem).
  - Starts coordinator stream listeners on `start()`.

- **`PreviewAppContainer.makePreview()`**:
  - Constructs pre-populated in-memory test doubles (`FakeLocationProvider`, `FakeWorkoutProvider`, `FakeSensorProvider`, `FakeHapticProvider`, `TestClock`).
  - Allows instant, deterministic SwiftUI canvas previews.

- **`TestAppContainerBuilder`**:
  - Modular test builder allowing granular injection of stubs, failures, and spies for unit/integration testing.
