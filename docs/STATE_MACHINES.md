# UltraNav Explicit State Machines (Phase 1C)

**Document Version:** 1.0.0  
**Date:** September 2026  
**Target:** UltraNav Apple Watch Ultra Cycling Computer

---

## 1. Overview

UltraNav decouples user intent and system callbacks from passive Boolean flags by enforcing deterministic, pure state machines:
- **`RideStateMachine`**: Coordinates ride lifecycle (preparation, starting, active recording, pausing, resumption, finishing, and failure recovery).
- **`NavigationStateMachine`**: Coordinates route loading, active navigation, deviation detection, off-route rejoining, completion, and failure recovery.

Both state machines are framework-independent value types (`Sendable` structs) with explicit `handle(_ event:) throws -> Transition` semantics.

---

## 2. Ride State Machine Matrix

### States
- `idle`: Initial resting state. No active ride session or hardware activity.
- `preparing`: Hardware authorizations and sensor checks requested.
- `ready`: All permissions and dependencies verified. Ready for user start.
- `starting`: Hardware recording and workout session startup initiated.
- `active`: Live ride in progress. Sensors, GPS, and metrics active.
- `pausing`: Pause requested; awaiting external services to suspend.
- `paused`: Workout and timer paused. GPS updates ignored for metrics.
- `resuming`: Resume requested; awaiting external services to resume.
- `finishing`: Stop requested; awaiting workout session finalization.
- `completed`: Ride finished, summarized, and saved.
- `failed(failure, recovery)`: Typed failure with deterministic recovery path.

### Transitions Table

| Current State | Event | Target State | Produced Effects |
| :--- | :--- | :--- | :--- |
| `idle` | `prepareRequested` | `preparing` | `[.prepareDependencies]` |
| `preparing` | `preparationSucceeded` | `ready` | `[]` |
| `preparing` | `preparationFailed(failure)` | `failed(failure, .returnToIdle)` | `[]` |
| `ready` | `startRequested` | `starting` | `[.startRide]` |
| `starting` | `startSucceeded` | `active` | `[]` |
| `starting` | `startFailed(failure)` | `failed(failure, .returnToReady)` | `[]` |
| `active` | `pauseRequested` | `pausing` | `[.pauseRide]` |
| `pausing` | `pauseSucceeded` | `paused` | `[]` |
| `pausing` | `pauseFailed(failure)` | `failed(failure, .returnToActive)` | `[]` |
| `paused` | `resumeRequested` | `resuming` | `[.resumeRide]` |
| `resuming` | `resumeSucceeded` | `active` | `[]` |
| `resuming` | `resumeFailed(failure)` | `failed(failure, .returnToPaused)` | `[]` |
| `active` | `finishRequested` | `finishing` | `[.finishRide]` |
| `paused` | `finishRequested` | `finishing` | `[.finishRide]` |
| `finishing` | `finishSucceeded` | `completed` | `[]` |
| `finishing` | `finishFailed(failure)` | `failed(failure, .retryFinishing)` | `[]` |
| `completed` | `resetRequested` | `idle` | `[.resetRide]` |
| `failed` | `resetRequested` | `idle` | `[.resetRide]` |
| `failed(_, .returnToIdle)` | `recoveryRequested` | `idle` | `[.resetRide]` |
| `failed(_, .returnToReady)` | `recoveryRequested` | `ready` | `[]` |
| `failed(_, .returnToActive)` | `recoveryRequested` | `active` | `[]` |
| `failed(_, .returnToPaused)` | `recoveryRequested` | `paused` | `[]` |
| `failed(_, .retryFinishing)` | `recoveryRequested` | `finishing` | `[.finishRide]` |
| `*` (any other combination) | `*` | **Throws** `RideTransitionError.invalidTransition` | State Unchanged |

---

## 3. Navigation State Machine Matrix

### States
- `inactive`: No active navigation or route loaded.
- `loading`: Route parsing or store fetch in progress.
- `ready`: Route loaded and verified. Ready for navigation start.
- `starting`: Navigation engine initialization in progress.
- `navigating`: Active on-course navigation with real-time XTE tracking.
- `suspectedOffRoute`: Initial off-course threshold exceeded; awaiting hysteresis confirmation.
- `offRoute`: Confirmed off-course deviation. Rejoin guidance active.
- `rejoining`: User re-intercepting route polyline.
- `finishing`: Route completion detected; concluding navigation.
- `finished`: Navigation successfully concluded.
- `failed(failure, recovery)`: Typed navigation failure with recovery route.

### Transitions Table

| Current State | Event | Target State | Produced Effects |
| :--- | :--- | :--- | :--- |
| `inactive` | `routeLoadRequested` | `loading` | `[.loadRoute]` |
| `loading` | `routeLoadSucceeded` | `ready` | `[]` |
| `loading` | `routeLoadFailed(failure)` | `failed(failure, .retryLoading)` | `[]` |
| `ready` | `navigationStartRequested` | `starting` | `[.initializeNavigation]` |
| `starting` | `navigationStartSucceeded` | `navigating` | `[]` |
| `starting` | `navigationStartFailed(failure)` | `failed(failure, .returnToReady)` | `[]` |
| `navigating` | `possibleDeviationDetected` | `suspectedOffRoute` | `[.notifyPossibleDeviation]` |
| `suspectedOffRoute` | `deviationConfirmed` | `offRoute` | `[.notifyOffRoute]` |
| `suspectedOffRoute` | `rejoinConfirmed` | `navigating` | `[]` |
| `offRoute` | `rejoinDetected` | `rejoining` | `[]` |
| `rejoining` | `rejoinConfirmed` | `navigating` | `[.notifyRouteRejoined]` |
| `navigating` / `suspectedOffRoute` / `rejoining` | `routeCompleted` | `finishing` | `[.finishNavigation]` |
| `finishing` | `finishSucceeded` | `finished` | `[]` |
| `finishing` | `finishFailed(failure)` | `failed(failure, .returnToNavigating)` | `[]` |
| `ready` / `starting` / `navigating` / `suspectedOffRoute` / `offRoute` / `rejoining` | `stopRequested` | `inactive` | `[.clearNavigation]` |
| `finished` / `failed` | `resetRequested` | `inactive` | `[.clearNavigation]` |
| `failed(_, .returnToInactive)` | `recoveryRequested` | `inactive` | `[.clearNavigation]` |
| `failed(_, .returnToReady)` | `recoveryRequested` | `ready` | `[]` |
| `failed(_, .returnToNavigating)` | `recoveryRequested` | `navigating` | `[]` |
| `failed(_, .retryLoading)` | `recoveryRequested` | `loading` | `[.loadRoute]` |
| `*` (any other combination) | `*` | **Throws** `NavigationTransitionError.invalidTransition` | State Unchanged |

---

## 4. Boolean State Migration Inventory

The following legacy Boolean flags in `CyclingRideEngine` and presentation views will be migrated to domain states in Phase 1H:

| Legacy Flag | Current Role | Target State Mapping | Planned Removal Phase |
| :--- | :--- | :--- | :--- |
| `isRiding: Bool` | Indicates ride active or paused | `RideState.hasActiveRideSession` (`.starting`, `.active`, `.pausing`, `.paused`, `.resuming`, `.finishing`) | Phase 1H |
| `isPaused: Bool` | Indicates ride paused | `RideState.paused` or `RideState.pausing` | Phase 1H |
| `isOffCourse: Bool` | Navigation deviation flag | `NavigationState == .offRoute` or `.suspectedOffRoute` | Phase 1H / Phase 5 |
| `isScanning: Bool` | Bluetooth scanning flag | `SensorProviding.isScanning` | Phase 1H / Phase 8 |
| `isSessionActive: Bool`| HealthKit workout session flag | `WorkoutProviding.isSessionActive` | Phase 1H / Phase 4 |
