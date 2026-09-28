# HealthKit Workout Architecture & Service Boundary (Phase 1F)

## Overview

In UltraNav, **all HealthKit workout interactions** (`HKHealthStore`, `HKWorkoutSession`, `HKLiveWorkoutBuilder`, `HKLiveWorkoutDataSource`, `HKWorkoutConfiguration`) are isolated behind the `WorkoutProviding` boundary inside `HealthKitService`.

```
HealthKit Framework
         │
         ├── HKHealthStore (Authorization)
         ├── HKWorkoutSession (Session Activity Lifecycle)
         ├── HKLiveWorkoutBuilder (Data Collection & Saving)
         └── HKLiveWorkoutDataSource
                 │
                 ▼
     HealthKitDelegateBridge
                 │
                 ▼
          HealthKitService
                 │
                 ▼ (HealthKitMetricConverter)
        WorkoutServiceEvent (.metricReceived, .workoutSaved, .stateChanged)
                 │
                 ▼
         Future RideEngine
```

---

## Key Invariants

1. **Zero Framework Leaks**: `RideEngine`, `MetricsEngine`, and SwiftUI views never import `HealthKit` or touch `HKWorkoutSession`. They consume Sendable `WorkoutServiceEvent` streams.
2. **Distinct Lifecycle**: `WorkoutServiceState` (`idle`, `authorizing`, `preparing`, `prepared`, `ready`, `starting`, `running`, `pausing`, `paused`, `resuming`, `stopping`, `finalizing`, `ended`, `failed`) is distinct from application `RideState`.
3. **Structured Metrics**:
   - Heart Rate is emitted as instantaneous `WorkoutMetric.heartRate`.
   - Energy and Distance are emitted as cumulative totals (`WorkoutMetric.activeEnergy`, `WorkoutMetric.cyclingDistance`).
4. **Reliable Finalization Sequence**:
   1. `session.stopActivity(at: endDate)`
   2. `builder.endCollection(at: endDate)`
   3. `builder.finishWorkout()` -> Returns `CompletedWorkoutReference`
   4. `session.end()`
5. **Recoverable State Transitions**: Bounded buffer (`.bufferingNewest(50)`) ensures stream capacity during high-frequency sensor updates.
