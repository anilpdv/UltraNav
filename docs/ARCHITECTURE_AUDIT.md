# Architecture Audit: UltraNav State & Subsystem Inventory

**Document Version:** 1.0.0 (Phase 1 Baseline)  
**Date:** September 2026  
**Target:** UltraNav Apple Watch Ultra Cycling Computer

---

## 1. Executive Summary

An architectural audit was performed on the existing UltraNav codebase to evaluate subsystem boundaries, state management, testability, and framework isolation. While the application successfully runs standalone on Apple Watch Ultra and passes unit tests, several core subsystems were centralized inside `CyclingRideEngine`, creating tight coupling between:
- Apple Hardware frameworks (`CoreLocation`, `CoreBluetooth`, `HealthKit`)
- Ride lifecycle state
- Navigation and Cross-Track Error calculations
- Metrics and Lap aggregation
- ClimbPro elevation profiling
- SwiftUI presentation bindings

Phase 1 establishes a modular, protocol-driven architecture with clean layer separation, Sendable domain models, explicit state machines, and dependency injection.

---

## 2. CyclingRideEngine Inventory & Classification

Every property, method, and dependency in `CyclingRideEngine` has been classified:

| Member | Current Type / Role | Classification | Target Architectural Destination |
| :--- | :--- | :--- | :--- |
| `isRiding`, `isPaused` | `Bool` Flags | **RIDE** | `RideState` State Machine (`RideEngine`) |
| `activeRoute` | `GPXRoute?` | **NAVIGATION** | `NavigationEngine` / `RouteStore` |
| `currentSpeedKmh`, `averageSpeedKmh`, `maxSpeedKmh` | `Double` | **METRICS** | `MetricsEngine` (`RideMetrics`) |
| `totalDistanceMeters`, `elapsedTime`, `movingTime` | `Double` / `TimeInterval` | **METRICS** | `MetricsEngine` (`RideMetrics`) |
| `currentElevationMeters`, `elevationGainedMeters` | `Double` | **CLIMB / METRICS** | `ClimbEngine` / `MetricsEngine` |
| `currentGradePercent`, `vamMetersPerHour` | `Double` | **CLIMB** | `ClimbEngine` (`ClimbSnapshot`) |
| `heartRate`, `cadenceRPM`, `powerWatts`, `activeCalories` | `Int` | **BLUETOOTH / METRICS** | `SensorProviding` -> `MetricsEngine` |
| `currentLocation`, `currentHeading` | `CLLocation?`, `Double` | **LOCATION** | `LocationProviding` (`LocationSample`) |
| `breadcrumbHistory` | `[CLLocationCoordinate2D]` | **NAVIGATION** | `NavigationEngine` (`[Coordinate]`) |
| `isOffCourse`, `crossTrackErrorMeters` | `Bool`, `CLLocationDistance` | **NAVIGATION** | `NavigationEngine` (`NavigationSnapshot`) |
| `nextCue`, `distanceToNextCue` | `RouteCue?`, `Double` | **NAVIGATION** | `NavigationEngine` (`NavigationSnapshot`) |
| `currentClimb`, `distanceRemainingInClimb` | `ClimbSegment?`, `Double` | **CLIMB** | `ClimbEngine` (`ClimbSnapshot`) |
| `laps`, `currentLapDuration`, `currentLapDistance` | `[LapRecord]`, `TimeInterval`, `Double` | **METRICS** | `MetricsEngine` |
| `locationManager` | `CLLocationManager` | **LOCATION** | `LocationService: LocationProviding` |
| `sensorManager` | `BluetoothSensorManager` | **BLUETOOTH** | `BluetoothService: SensorProviding` |
| `workoutManager` | `WorkoutSessionManager` | **HEALTHKIT** | `HealthKitService: WorkoutProviding` |
| `startRide()`, `pauseRide()`, `resumeRide()`, `finishRide()` | Lifecycle Methods | **RIDE** | `RideEngine` |
| `triggerManualLap()` | Lap Mutation | **METRICS** | `MetricsEngine` |
| `processLocationUpdate(...)` | Location Dispatch | **LOCATION / ENGINE** | `LocationService` -> `RideEngine` |
| `updateGradientAndVAM(...)` | Elevation Math | **CLIMB** | `ClimbEngine` |
| `updateNavigationStatus(...)` | XTE / Route Progress | **NAVIGATION** | `NavigationEngine` |

---

## 3. Identified Architectural Smells & Anti-Patterns

1. **Centralized God Object (`CyclingRideEngine`)**:
   - Manages GPS, Bluetooth peripherals, HealthKit workout session, 1-second UI timers, lap records, and GPX geometry concurrently.
   - Makes isolated unit testing of navigation or metrics impossible without mocking all 3 system hardware managers simultaneously.

2. **Distributed Boolean Flags**:
   - `isRiding: Bool`, `isPaused: Bool`, `isOffCourse: Bool`, `isScanning: Bool`, `isSessionActive: Bool`.
   - Permits illegal combinations (e.g. `isRiding == false && isPaused == true`).

3. **Platform Type Leaks in Domain**:
   - `CLLocationCoordinate2D`, `CLLocation`, and `CLLocationDistance` used directly across presentation and domain instead of pure Swift Sendable structs (`Coordinate`, `LocationSample`).

4. **Singleton Centralization**:
   - `CyclingRideEngine.shared`, `BluetoothSensorManager.shared`, `WorkoutSessionManager.shared` prevent test double injection and multi-instance unit testing.

5. **Direct View Coupling to Hardware State**:
   - Views like `OfflineBreadcrumbMapView` compute equirectangular coordinates and zoom matrix directly in `Canvas` closures from raw mutable engine properties.

---

## 4. Phase 1 Migration Strategy

| Subsystem | Existing File / Type | Action | Target Destination |
| :--- | :--- | :--- | :--- |
| **Ride State** | `isRiding`, `isPaused` flags | **REPLACE** | `Domain/Ride/RideState.swift` (Explicit State Machine) |
| **Ride Snapshot** | Mutable properties in `CyclingRideEngine` | **EXTRACT** | `Domain/Ride/RideSnapshot.swift` (Immutable Sendable model) |
| **Domain Geometry** | `CLLocationCoordinate2D` | **EXTRACT** | `Domain/Navigation/Coordinate.swift`, `LocationSample.swift` |
| **Location Service** | Embedded `CLLocationManager` | **ISOLATE** | `Services/Location/LocationProviding.swift` + `LocationService.swift` |
| **HealthKit Service** | `WorkoutSessionManager` | **WRAP** | `Services/HealthKit/WorkoutProviding.swift` + `HealthKitService.swift` |
| **Bluetooth Service** | `BluetoothSensorManager` | **WRAP** | `Services/Bluetooth/SensorProviding.swift` + `BluetoothService.swift` |
| **Navigation Engine** | XTE / Cues in `CyclingRideEngine` | **EXTRACT** | `Engines/NavigationEngine.swift` + `NavigationSnapshot.swift` |
| **Metrics Engine** | Speed/Power/Cadence/Laps in Engine | **EXTRACT** | `Engines/MetricsEngine.swift` + `RideMetrics.swift` |
| **Climb Engine** | Grade / VAM in Engine | **EXTRACT** | `Engines/ClimbEngine.swift` + `ClimbSnapshot.swift` |
| **Composition Root** | Ad-hoc singletons | **INTENTIONAL DI** | `App/AppContainer.swift` |
| **Test Doubles** | No hardware mocks | **CREATE** | `FakeLocationService`, `FakeWorkoutService`, `FakeSensorService`, `TestClock` |

---

## 5. Non-Goals for Phase 1

- **Do NOT rewrite GPX XML parsing algorithms** (Reserved for Phase 2).
- **Do NOT alter GPS filtering / Kalman algorithms** (Reserved for Phase 3).
- **Do NOT overhaul BLE GATT characteristic parsing byte offsets** (Reserved for Phase 8).
- **Do NOT redesign SwiftUI screen layouts or color themes** (Reserved for Phase 11).

Phase 1 provides the solid, testable architectural boundary scaffolding required so subsequent phases can safely upgrade domain algorithms.

---

## 6. Phase 1B Baseline

Commit: `10cd8384ac55f041d0b6cff15951adcf64da3a8f`

Build:
- Status: PASS
- Targets: `UltraNav`, `UltraNavWidget`, `UltraNavTests`, `UltraNavUITests`

Tests:
- Executed: 22 tests across test suites
- Target platform: `watchOS Simulator (Apple Watch Ultra 2 / Ultra 4 - 49mm)`

---

## 7. Phase 1E Location Ownership Audit

### CLLocationManager creation sites
- `UltraNav/Services/Location/LocationService.swift`: Production `CLLocationManager` owner.

### CLLocationManagerDelegate implementations
- `UltraNav/Services/Location/CoreLocationDelegateBridge.swift`: Isolated delegate bridge forwarding callbacks to `LocationService`.

### Raw CLLocation consumers
- `UltraNav/Services/Location/CoreLocationSampleConverter.swift`: Normalizes raw `CLLocation` to domain `LocationSample`.
- `UltraNav/Infrastructure/Adapters/LocationAdapters.swift`: Legacy bridge extensions for view previews.

### Direct UI access
- None. Views access `Coordinate` or `LocationSample` via snapshots published by engines.

### Duplicate state
- None. `LocationService` is the single source of location updates.

### Current configuration
- desiredAccuracy: `10.0` meters (`kCLLocationAccuracyBestForNavigation` requested via `LocationConfiguration.cycling`)
- distanceFilter: `2.0` meters
- activityType: `.fitness`
- background updates: `true`
- automatic pausing: `false`

### Migration decisions
- `CLLocationManager` creation -> Owned exclusively by `LocationService`
- `CLLocation` conversion -> Managed by `CoreLocationSampleConverter`
- GPS filtering / validation -> Deferred to Phase 3 (Location & Sensor Fusion)

