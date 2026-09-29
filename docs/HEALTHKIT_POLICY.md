# HealthKit Workout Policy

UltraNav interacts with HealthKit strictly through the `HealthKitService` implementation of the `WorkoutProviding` protocol to ensure deterministic session management, reliable metric streaming, and zero data loss on platform failures.

## 1. Lifecycle Guarantees

1. **Explicit Authorization Gate**:
   - `requestAuthorization()` must be invoked before attempting workout preparation.
   - If authorization is denied or unavailable, `prepare()` immediately throws `.authorizationDenied` and moves to `.failed`.

2. **Resource Allocation & Cleanup**:
   - Session and live workout builder instances are created only during `prepare()`.
   - On `start(at:)` failure or `finish(at:)` failure, all allocated session and builder resources are cleanly ended and set to `nil` to prevent leaked background sessions.

3. **Synchronous Transition Confirmation**:
   - `prepare()` prepares the platform session and moves state to `.ready`.
   - `start(at:)` begins builder collection, starts session activity, and sets state to `.running`.
   - `pause()` pauses activity and sets state to `.paused`.
   - `resume()` resumes activity and sets state to `.running`.

4. **Multi-Stage Finalization**:
   - `finish(at:)` captures the finish timestamp once and applies it to:
     1. `session.stopActivity(at: date)`
     2. `builder.endCollection(at: date)`
     3. `builder.finishWorkout()`
     4. `session.end()`
   - Emits `.finalizationStarted` followed by `.workoutSaved(completedWorkout)`.

5. **Failure Resilience & Data Preservation**:
   - HealthKit workout save failure does not erase locally tracked metrics, GPS samples, or navigation state.
   - All failures yield typed `.failed(WorkoutServiceFailure)` events on the event stream.
