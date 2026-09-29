# Phase 4 Baseline: HealthKit Workout Reliability

## 1. Overview
Audit of current HealthKit integration, workout session management, lifecycle states, and metric conversion in UltraNav.

## 2. Component Inventory
- **Workout Service Protocol**: `WorkoutProviding.swift`
  - Defines `authorizationStatus()`, `requestAuthorization()`, `prepare()`, `start(at:)`, `pause()`, `resume()`, `finish(at:)`, `cancel()`, and `reset()`.
  - Exposes `events: AsyncStream<WorkoutServiceEvent>`.
- **Primary Service**: `HealthKitService.swift`
  - Manages `HKWorkoutSession` via `HealthKitSessionManaging` abstraction.
  - Manages `HKLiveWorkoutBuilder` via `HealthKitBuilderManaging` abstraction.
  - Uses `HealthKitDelegateBridge` to isolate platform callbacks.
- **Factory & Test Doubles**:
  - `HealthKitWorkoutFactory.swift` creates real HealthKit objects.
  - `FakeWorkoutFactory.swift`, `FakeWorkoutSession.swift`, `FakeWorkoutBuilder.swift`, `FakeHealthStore.swift` enable 100% deterministic off-device unit testing without HealthKit entitlement crashes.
- **Metric Conversion**:
  - `HealthKitMetricConverter.swift` normalizes `HKQuantityType` (heart rate in BPM, active energy in kcal, cycling distance in meters) into immutable `WorkoutMetric` and `WorkoutServiceEvent` instances.

## 3. Key Reliability Goals for Phase 4
1. **Confirmed State Transitions**:
   - `start(at:)` only resolves when the builder and session are actively running.
   - `pause()` and `resume()` resolve upon platform state confirmation.
   - `finish(at:)` executes atomic 3-step finalization (session stop, builder collection end, workout save).
2. **Failure Isolation & Resource Cleanup**:
   - Failed preparation or start clears sessions and builders to prevent leaked platform sessions.
   - Save failures preserve ride metrics, route, and GPS data for local persistence.
3. **Thread Safety & Cancellation**:
   - MainActor isolation on `HealthKitService` prevents concurrent delegate race conditions.
   - `cancel()` and `reset()` cleanly terminate session without unhandled crashes.
