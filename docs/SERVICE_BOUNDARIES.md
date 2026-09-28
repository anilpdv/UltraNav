# UltraNav Service Protocol Boundaries (Phase 1D)

**Document Version:** 1.0.0  
**Date:** September 2026  
**Target:** UltraNav Apple Watch Ultra Cycling Computer

---

## 1. Architectural Philosophy

Phase 1D establishes pure, testable protocol interfaces between UltraNav domain logic and Apple platform frameworks (`CoreLocation`, `CoreBluetooth`, `HealthKit`, file storage, and hardware clocks).

### Key Rules
1. **Capabilities over Implementations**: Protocols represent domain capabilities (`LocationProviding`, `WorkoutProviding`, `SensorProviding`, `RouteStoring`, `RidePersisting`, `ClockProviding`), not concrete SDK managers.
2. **Framework Isolation**: 0 Apple framework types (`CLLocation`, `HKWorkoutSession`, `CBPeripheral`) appear in protocol signatures.
3. **Structured Event Delivery**: Asynchronous event streams use `AsyncStream<Event>` with structured concurrency, eliminating notification strings and fragile delegate graphs.
4. **Separation of Commands and Observations**: Commands (`startUpdates()`, `start(at:)`) request work; event streams deliver continuous observations.
5. **Typed Failure Mapping**: Raw OS errors (`CLError`, `HKError`, `CBError`) are mapped at the service boundary to typed domain errors.

---

## 2. Service Protocol Matrix

### Location (`LocationProviding`)
- **Protocol:** [`LocationProviding`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Location/LocationProviding.swift)
- **Status Model:** [`LocationAuthorizationStatus`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Location/LocationAuthorizationStatus.swift) (`.notDetermined`, `.restricted`, `.denied`, `.authorized`)
- **Failure Model:** [`LocationServiceFailure`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Location/LocationServiceFailure.swift) (`.authorizationDenied`, `.authorizationRestricted`, `.servicesDisabled`, `.updatesUnavailable`, `.updateFailed`, `.alreadyRunning`, `.unexpected`)
- **Events:** [`LocationServiceEvent`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Location/LocationServiceEvent.swift) (`.authorizationChanged`, `.updateStarted`, `.locationReceived(LocationSample)`, `.updateStopped`, `.failed`)
- **Test Double:** [`FakeLocationProvider`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/FakeLocationProvider.swift)

### Workout (`WorkoutProviding`)
- **Protocol:** [`WorkoutProviding`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Workout/WorkoutProviding.swift)
- **Status Model:** [`WorkoutAuthorizationStatus`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Workout/WorkoutAuthorizationStatus.swift) (`.notDetermined`, `.denied`, `.authorized`, `.unavailable`)
- **Service State:** [`WorkoutServiceState`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Workout/WorkoutServiceState.swift) (`.idle`, `.preparing`, `.ready`, `.starting`, `.running`, `.pausing`, `.paused`, `.resuming`, `.ending`, `.ended`, `.failed`)
- **Failure Model:** [`WorkoutServiceFailure`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Workout/WorkoutServiceFailure.swift) (`.healthDataUnavailable`, `.authorizationDenied`, `.preparationFailed`, `.startFailed`, `.pauseFailed`, `.resumeFailed`, `.finishFailed`, `.invalidServiceState`, `.unexpected`)
- **Events:** [`WorkoutServiceEvent`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Workout/WorkoutServiceEvent.swift) (`.authorizationChanged`, `.stateChanged`, `.heartRateReceived`, `.activeEnergyReceived`, `.distanceReceived`, `.failed`)
- **Test Double:** [`FakeWorkoutProvider`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/FakeWorkoutProvider.swift)

### Sensors (`SensorProviding`)
- **Protocol:** [`SensorProviding`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Sensors/SensorProviding.swift)
- **Identifier:** [`SensorIdentifier`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Sensors/SensorIdentifier.swift) (Sendable string wrapper)
- **Descriptor:** [`SensorDescriptor`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Sensors/SensorDescriptor.swift)
- **Failure Model:** [`SensorServiceFailure`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Sensors/SensorServiceFailure.swift) (`.bluetoothUnavailable`, `.bluetoothUnauthorized`, `.scanFailed`, `.connectionFailed`, `.discoveryFailed`, `.notificationSetupFailed`, `.disconnectedUnexpectedly`, `.malformedMeasurement`, `.unexpected`)
- **Events:** [`SensorServiceEvent`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Sensors/SensorServiceEvent.swift) (`.serviceAvailabilityChanged`, `.scanStarted`, `.sensorDiscovered`, `.scanStopped`, `.connectionStateChanged`, `.sampleReceived`, `.failed`)
- **Test Double:** [`FakeSensorProvider`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/FakeSensorProvider.swift)

### Routes Storage (`RouteStoring`)
- **Protocol:** [`RouteStoring`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Routes/RouteStoring.swift)
- **Summary Model:** [`RouteSummary`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Routes/RouteSummary.swift)
- **Error Model:** [`RouteStoreError`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Routes/RouteStoreError.swift) (`.routeNotFound`, `.duplicateRoute`, `.invalidRoute`, `.readFailed`, `.writeFailed`, `.deleteFailed`, `.storageUnavailable`, `.unexpected`)
- **Test Double:** [`FakeRouteStore`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/FakeRouteStore.swift)

### Ride Persistence (`RidePersisting`)
- **Protocol:** [`RidePersisting`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Persistence/RidePersisting.swift)
- **Record Model:** [`CompletedRide`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Domain/Ride/CompletedRide.swift)
- **Error Model:** [`RidePersistenceError`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Services/Persistence/RidePersistenceError.swift)
- **Test Double:** [`FakeRidePersistence`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/FakeRidePersistence.swift)

### Time & Infrastructure (`ClockProviding`, `SleepProviding`)
- **Protocol:** [`ClockProviding`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Infrastructure/Time/ClockProviding.swift), [`SleepProviding`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Infrastructure/Time/SleepProviding.swift)
- **Production Impl:** [`SystemClock`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Infrastructure/Time/SystemClock.swift), [`SystemSleeper`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNav/Infrastructure/Time/SleepProviding.swift)
- **Test Double:** [`TestClock`](file:///Users/anilpdv/Documents/learning/sideprojects/applewatch/UltraNavTests/TestDoubles/TestClock.swift) (Thread-safe `NSLock` protected)

---

## 3. Error Mapping Taxonomy

| Platform Error Source | Service Boundary Mapping | RideEngine Lifecycle Mapping |
| :--- | :--- | :--- |
| `CLAuthorizationStatus.denied` | `LocationAuthorizationStatus.denied` | `RideFailure.locationPermissionDenied` |
| `CLError.denied` | `LocationServiceFailure.authorizationDenied` | `RideFailure.locationPermissionDenied` |
| `HKError.errorAuthorizationDenied` | `WorkoutServiceFailure.authorizationDenied` | `RideFailure.workoutAuthorizationDenied` |
| `HKWorkoutSession` startup error | `WorkoutServiceFailure.startFailed` | `RideFailure.workoutStartFailed` |
| `CBCentralManager` power off | `SensorServiceFailure.bluetoothUnavailable` | Nonfatal (Ride continues on GPS/Watch) |
| `CBPeripheral` unexpected disconnect | `SensorServiceFailure.disconnectedUnexpectedly` | Nonfatal (Ride continues with sensor retry) |
| Missing GPX file / route | `RouteStoreError.routeNotFound` | `NavigationFailure.routeUnavailable` |
