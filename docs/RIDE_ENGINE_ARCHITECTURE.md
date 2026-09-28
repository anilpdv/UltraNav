# RideEngine Architecture & Lifecycle Coordination

## 1. Overview

`RideEngine` is the centralized, framework-independent coordinator for UltraNav's ride lifecycle on watchOS. It assembles the domain abstractions and platform service boundaries introduced in Phases 1B through 1G into a strictly isolated, testable state machine coordinator.

`RideEngine` owns:
- Explicit ride lifecycle state machine (`RideStateMachine`)
- Coordination of mandatory dependencies (`LocationProviding`, `WorkoutProviding`)
- Optional accessory monitoring (`SensorProviding`)
- Continuous service event streams and task lifecycle
- Deterministic timing calculation (`RideTimingState`)
- Lightweight snapshot metric caching (`RideMetricState`)
- Subsystem status, degradation tracking, and failure mapping
- Immutable snapshot publication (`AsyncStream<RideSnapshot>`)
- Atomic preparation, startup, pause, resume, finish, recovery, and reset rollbacks

`RideEngine` does **NOT** own:
- Apple framework classes (`CLLocationManager`, `HKWorkoutSession`, `CBCentralManager`, `CBPeripheral`)
- Raw BLE byte parsing (handled by `SensorPacketParsing`)
- GPX parsing or route storage (handled by `RouteStoring`)
- Navigation geometry, turn cues, or off-route calculations (handled by `NavigationEngine` in Phase 1I)
- Advanced cycling calculations (NP, IF, TSS, power zones handled by `MetricsEngine` in Phase 1J)
- Climb detection (handled by `ClimbEngine` in Phase 1K)
- SwiftUI presentation bindings or localized string formatting

---

## 2. Architecture & Data Flow

```
                   User Intent
                       │
                       ▼
           [send(RideEngineCommand)]
                       │
                       ▼
             ┌───────────────────┐
             │    RideEngine     │
             │                   │
             │ ┌───────────────┐ │
             │ │RideStateMachine│ │
             │ └───────────────┘ │
             │ ┌───────────────┐ │
             │ │RideTimingState│ │
             │ └───────────────┘ │
             │ ┌───────────────┐ │
             │ │RideMetricState│ │
             │ └───────────────┘ │
             └─────────┬─────────┘
                       │
            AsyncStream<RideSnapshot>
                       │
                       ▼
             ┌───────────────────┐
             │Presentation Views │
             │ (Legacy Adapter)  │
             └───────────────────┘
```

### Event Flow from Boundaries:

```
CoreLocation ──► LocationService ──► LocationServiceEvent ──► RideEngine ──► RideSnapshot
HealthKit    ──► HealthKitService ──► WorkoutServiceEvent  ──► RideEngine ──► RideSnapshot
CoreBluetooth──► BluetoothService ──► SensorServiceEvent   ──► RideEngine ──► RideSnapshot
```

---

## 3. Dependency Policy & Lifecycle Guarantees

### Mandatory vs Optional Subsystems:
Under `RideDependencyPolicy.outdoorCycling`:
- **Location**: Mandatory for outdoor cycling. Permission denial or service failure blocks preparation/start.
- **Workout**: Mandatory. HealthKit workout session must prepare and start.
- **Sensors**: Optional. Bluetooth unavailability, sensor disconnections, or malformed packets do **not** fail or pause the ride; they are recorded as subsystem degradations (`.sensorsUnavailable`).

### Atomic Rollback:
- **Preparation Failure**: If location succeeds but workout fails to prepare, location is rolled back (`stopUpdates()`), workout is reset (`reset()`), and the ride transitions to `.failed(failure:recovery:.returnToIdle)`.
- **Start Failure**: If workout starts but location update start fails, the workout is immediately cancelled (`cancel()`), location is stopped, and the ride transitions to `.failed(failure:recovery:.returnToReady)`.

---

## 4. Timing Semantics

`RideTimingState` calculates time deterministically based on timestamps from `ClockProviding`:
- **Elapsed Time**: Total duration from `startedAt` to `endedAt ?? now`, including all paused segments.
- **Moving Time**: Accumulated active time across all active ride segments, strictly excluding pause intervals.
- **Finish Timestamping**: `finish(at: finishDate)` captures the exact user intent date before asynchronous service teardown occurs.

---

## 5. Subsystem Status & Degradations

`RideSnapshot` contains fine-grained diagnostic state:
- `RideLocationStatus`: `.unavailable`, `.preparing`, `.ready`, `.active`, `.failed`
- `RideWorkoutStatus`: `.unavailable`, `.preparing`, `.ready`, `.active`, `.paused`, `.finalizing`, `.ended`, `.failed`
- `RideSensorStatus`: `bluetoothAvailable`, `connectedSensorCount`, `readySensorCount`
- `RideDegradation`: `.locationUnavailable`, `.sensorsUnavailable`, `.workoutMetricsUnavailable`
