# Phase 4 Implementation Map

## Health store ownership
- **File**: `UltraNav/Services/Workout/HealthKitAuthorizing.swift`
- **Type**: `HealthKitAuthorizationClient`, `FakeHealthStore`
- **Consumers**: `HealthKitService`, `AppContainer`

## Authorization
- **Requested share types**: `HKWorkoutType`, `HKQuantityType(.activeEnergyBurned)`, `HKQuantityType(.distanceCycling)`
- **Requested read types**: `HKQuantityType(.heartRate)`, `HKQuantityType(.activeEnergyBurned)`, `HKQuantityType(.distanceCycling)`
- **Status model**: `WorkoutAuthorizationStatus` (`.notDetermined`, `.authorized`, `.denied`, `.unavailable`)
- **Error behavior**: Returns `.notDetermined` or `.unavailable` on error; never crashes on missing entitlements in tests.

## Workout resources
- **Configuration owner**: `WorkoutConfiguration.outdoorCycling`
- **Session creation**: `HealthKitWorkoutResourceCreating.createResources(configuration:delegateBridge:)`
- **Builder creation**: Bundled with session via factory
- **Data source creation**: `HKLiveWorkoutDataSource` (registered in factory)

## Lifecycle methods
- **Prepare**: Allocates session/builder, registers delegates, calls `session.prepare()`, transitions state to `.ready`.
- **Start**: Calls `builder.beginCollection(at:)` and `session.startActivity(at:)`, transitions state to `.running`.
- **Pause**: Calls `session.pause()`, transitions state to `.paused`.
- **Resume**: Calls `session.resume()`, transitions state to `.running`.
- **Finish**: Calls `session.stopActivity(at:)`, `builder.endCollection(at:)`, `builder.finishWorkout()`, `session.end()`, transitions state to `.ended`, emits `.workoutSaved`.
- **Cancel**: Ends session immediately, resets references to nil, transitions state to `.idle`.
- **Reset**: Validates ended/failed state, clears all references, transitions state to `.idle`.

## Delegates
- **Workout session delegate**: `HealthKitDelegateBridge` -> `workoutSessionChanged(to:from:at:)`, `workoutSessionFailed(_:)`
- **Live builder delegate**: `HealthKitDelegateBridge` -> `workoutBuilderCollected(statisticsFor:)`
- **Callback isolation**: `@MainActor` on `HealthKitService` ensures serial processing.
- **Duplicate callback protection**: Guarded against state transitions when already in target state.

## Metrics
- **Heart rate**: Converted from `count/min` -> `Int` BPM.
- **Active energy**: Converted from `kilocalorie` -> `Double` kcal.
- **Cycling distance**: Converted from `meter` -> `Double` meters.

## Migration decisions
- `WorkoutSessionManager` -> `HealthKitService` (Deleted in Phase 1, verified absent)
- `HealthKitWorkoutFactory` -> Retained as production resource factory
- `FakeWorkoutFactory` -> Retained for all test scenarios
