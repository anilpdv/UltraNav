# UltraNav Improvement Backlog

This backlog converts the repository-verified gaps in `docs/feature-gap-analysis.md` into implementation-ready work. Priorities reflect user safety, core navigation reliability, watchOS platform value, accessibility, privacy, and release risk.

## Priority definitions

- **P0**: Required for a reliable and safe primary navigation flow. A release should not proceed while the item is incomplete.
- **P1**: High-value product or platform work that materially improves resilience, accessibility, and watchOS usefulness.
- **P2**: Release maturity, observability, optimisation, and secondary experience improvements.

## Completion rules

An item is complete only when:

1. The expected behaviour is implemented in the named screen or component.
2. Its automated test requirement passes.
3. Its measurable completion metric is satisfied.
4. User-facing failures provide an actionable recovery path.
5. Relevant accessibility identifiers and labels are present.
6. No new compiler warnings are introduced.

---

# P0: Core navigation reliability

## P0-01: Deterministic search and route screen states

**Verified gaps:** GAP-EMP-01, GAP-EMP-02, GAP-STATE-01, GAP-STATE-02, GAP-STATE-03  
**Components:** `NavigationModel.swift`, `ContentView.swift`, `SearchView`, `RoutePreviewView`, `NavigationView`

### Expected behaviour

- Represent idle, searching, empty search, route calculation, preview, navigation, rerouting, and failure as explicit states.
- Display a visible loading state while searching or calculating a route.
- Display a dedicated zero-result state that preserves the submitted query.
- Display a clear GPS-waiting or location failure state instead of leaving the screen blank.
- Keep active guidance visible while a background reroute is attempted.
- Prevent stale asynchronous results from replacing newer screen state.

### Test requirement

- Unit tests cover every valid state transition.
- Unit tests verify that an obsolete search or route task cannot overwrite the latest result.
- UI tests cover loading, no results, route preview, navigation, rerouting, and error presentation.

### Completion metric

- Every primary asynchronous operation has exactly one visible loading, loaded, empty, or failed outcome.
- No primary screen can render as an unexplained blank screen.
- All state-transition tests pass deterministically for 20 consecutive runs.

---

## P0-02: Operation-specific retry and recovery

**Verified gaps:** GAP-STATE-04, GAP-REC-01, GAP-REC-02, GAP-REC-03  
**Components:** `NavigationModel.swift`, `ErrorStateView.swift`, `RetryButton.swift`

### Expected behaviour

- Record whether the failed operation was location acquisition, destination search, route calculation, or rerouting.
- Retry only the failed operation.
- Preserve the search query when search fails.
- Preserve the selected destination when route calculation fails.
- Preserve the last valid route and active guidance when rerouting fails.
- Disable duplicate retry submissions while a retry is running.

### Test requirement

- Unit tests verify operation-specific retry dispatch.
- Unit tests verify preservation of search and destination context.
- Unit tests verify that reroute failure does not discard an active route.
- UI test simulates a failure followed by a successful retry.

### Completion metric

- Every recoverable failure exposes a retry action.
- Retry resumes from the failed step without forcing the user to re-enter valid context.
- Repeated taps create no duplicate MapKit requests.

---

## P0-03: Cancel and serialise asynchronous work

**Verified gaps:** GAP-STATE-05, GAP-ENG-01  
**Components:** `NavigationModel.swift`, MapKit search and directions adapters

### Expected behaviour

- Cancel an existing search before starting a new search.
- Cancel obsolete route calculations when the destination changes.
- Keep task ownership outside SwiftUI view bodies.
- Check cancellation before committing results.
- Execute observable UI-state mutations on the main actor.
- Introduce injectable protocols for search, directions, and location services so cancellation and failure paths are testable.

### Test requirement

- Unit tests use controllable fakes to complete requests out of order.
- Unit tests verify only the newest request can update visible state.
- Swift concurrency checks compile without actor-isolation errors.

### Completion metric

- One active search task and one active route task maximum.
- Zero stale-result state updates in concurrency tests.
- Debug watchOS Simulator build succeeds with Swift 6 concurrency checking.

---

## P0-04: Correct location lifecycle and navigation shutdown

**Verified gaps:** GAP-BG-02, GAP-BG-03, GAP-PRV-04  
**Components:** `NavigationModel.swift`, app entitlements, target capabilities, usage descriptions

### Expected behaviour

- Start continuous location updates only when necessary for route preview or active navigation.
- Stop updates when navigation ends and when continuous updates are no longer required.
- Do not claim or enable background location behaviour unless the target capabilities, plist declarations, and implementation are aligned.
- Handle denied, restricted, unavailable, and transient location failures explicitly.
- Avoid retaining raw location history beyond values required for current guidance.

### Test requirement

- Unit tests verify location start and stop calls for launch, preview, navigation, failure, and stop flows.
- Configuration test verifies entitlements and usage descriptions match actual behaviour.
- Manual device test verifies navigation stops consuming location after the user ends a ride.

### Completion metric

- Location updates stop within one state transition after navigation is ended.
- No mismatch exists between code, capabilities, entitlements, and user-facing disclosure.
- Location lifecycle tests pass.

---

## P0-05: Reusable loading, empty, error, and retry UI

**Verified gaps:** GAP-EMP-01, GAP-STATE-01, GAP-STATE-03, GAP-STATE-04  
**Components:** `Shared/UI/LoadingView.swift`, `Shared/UI/EmptyStateView.swift`, `Shared/UI/ErrorStateView.swift`, `Shared/UI/RetryButton.swift`, all primary screens

### Expected behaviour

- Add reusable components for loading, empty, error, and retry states.
- Components support concise title, message, system image, and optional action content.
- Error presentation includes an accessible retry control when recovery is possible.
- Replace duplicated or silent state markup in all primary screens.

### Test requirement

- SwiftUI view tests or UI tests verify each reusable state renders its title, message, and action.
- Accessibility tests verify labels and identifiers.
- Snapshot checks cover supported compact watch sizes where available.

### Completion metric

- All primary screens use the shared components.
- No indefinite spinner appears without explanatory text.
- No recoverable error lacks an action.

---

## P0-06: Arrival and completed-trip state

**Verified gap:** GAP-REC-04  
**Components:** `NavigationModel.swift`, `ArrivalView.swift`, `NavigationView`

### Expected behaviour

- Detect arrival using destination proximity and route progress with a conservative accuracy threshold.
- Transition once from navigating to arrived.
- Present a visible and accessible arrival confirmation.
- Stop continuous navigation updates after confirmation.
- Allow the user to dismiss the completed trip and return to search.
- Do not mark arrival from an inaccurate or stale location sample.

### Test requirement

- Unit tests cover outside threshold, inside threshold, inaccurate sample, repeated samples, and completed-trip reset.
- UI test verifies arrival confirmation and return to search.

### Completion metric

- Arrival is emitted at most once per trip.
- The completed-trip screen always offers a clear exit.
- All arrival boundary tests pass.

---

## P0-07: Establish test targets for the critical journey

**Verified gap:** GAP-ENG-02  
**Components:** Xcode project, `UltraNavTests`, `UltraNavUITests`

### Expected behaviour

- Add unit and UI test targets to the Xcode project.
- Make MapKit and Core Location dependencies replaceable by test doubles.
- Cover search, destination selection, route calculation, start, reroute, stop, failure, retry, and arrival.
- Ensure tests do not require live network or GPS services.

### Test requirement

- The test targets themselves must build and execute using a watchOS Simulator destination.
- A smoke UI test launches the application and locates the destination search control.

### Completion metric

- Critical state and recovery paths have automated coverage.
- Tests run without external network or physical location.
- The configured test command exits successfully.

---

# P1: Resilience, onboarding, settings, and watchOS value

## P1-01: Cache last successful user-visible data

**Verified gaps:** GAP-OFF-01, GAP-OFF-02  
**Components:** `AppCache.swift`, `SyncCoordinator.swift`, `NavigationModel.swift`, search and route screens

### Expected behaviour

- Persist only the minimum data needed to restore recent user-visible context.
- Load cached content at launch before attempting refresh.
- Mark cached content as stale when its freshness threshold expires.
- Show connectivity-aware messaging without blocking access to valid cached content.
- Never present cached route guidance as live navigation without a fresh location and route validation.

### Test requirement

- Unit tests cover save, load, expiry, corrupt data, schema mismatch, and cache clearing.
- UI test launches with cached content while the network service is unavailable.

### Completion metric

- Valid cached content appears without network access.
- Stale data is visibly labelled.
- Corrupt cache data falls back safely without crashing.

---

## P1-02: Restore interrupted navigation safely

**Verified gap:** GAP-OFF-04  
**Components:** `AppCache.swift`, `NavigationModel.swift`, `ResumeNavigationView.swift`

### Expected behaviour

- Save minimal trip context when navigation begins.
- On relaunch, offer to recalculate and resume rather than silently resuming stale guidance.
- Require a current location and a newly calculated route before active guidance restarts.
- Allow the user to discard saved trip context.
- Clear saved trip data after arrival or explicit stop.

### Test requirement

- Unit tests cover save, restore, discard, completion, invalid destination data, and failed recalculation.
- UI test covers the relaunch resume prompt.

### Completion metric

- An interrupted trip can be recovered without re-entering the destination.
- Guidance never resumes from a stale route without recalculation.
- Completed or discarded trips do not reappear.

---

## P1-03: Offline-safe mutation and reconciliation policy

**Verified gap:** GAP-OFF-03  
**Components:** `SyncCoordinator.swift`, settings mutations, future safe user preferences

### Expected behaviour

- Queue only idempotent, locally safe preference changes.
- Do not queue route searches, navigation starts, or other time-sensitive operations.
- Reconcile queued preferences when connectivity returns.
- Resolve conflicts deterministically using a documented policy.
- Expose sync failure without blocking navigation.

### Test requirement

- Unit tests cover queue insertion, deduplication, replay, conflict handling, and permanent failure.
- Tests verify prohibited operation types cannot enter the queue.

### Completion metric

- Queued safe changes replay exactly once.
- Duplicate changes collapse to the latest intended value.
- Navigation operations are never replayed from an offline queue.

---

## P1-04: First-launch onboarding and contextual location permission

**Verified gaps:** GAP-ONB-01, GAP-ONB-02  
**Components:** `OnboardingView.swift`, app entry point, `NavigationModel.swift`

### Expected behaviour

- Explain UltraNav's cycling-navigation value in concise, wrist-readable screens.
- Explain why location is needed before invoking the system prompt.
- Request permission only when the user starts a location-dependent flow.
- Handle denied permission with guidance to system settings.
- Persist onboarding completion and provide a way to revisit it.

### Test requirement

- UI tests cover first launch, skip or continue, permission rationale, denied permission, and subsequent launch.
- Unit test verifies onboarding completion persistence.

### Completion metric

- The system location prompt is never the first unexplained screen.
- Returning users do not repeat onboarding unless reset.
- Denied users receive a clear non-looping recovery path.

---

## P1-05: Settings and reset controls

**Verified gaps:** GAP-SET-01, GAP-SET-02, GAP-SET-03, GAP-PRV-02  
**Components:** `SettingsView.swift`, app navigation, local preferences

### Expected behaviour

- Provide controls for notification and background refresh preferences when those features are available.
- Show current permission status without impersonating system settings.
- Link to concise in-app privacy information.
- Allow reset of onboarding, cached content, and saved trip state.
- Confirm destructive reset before execution.

### Test requirement

- Unit tests verify preference persistence and reset scope.
- UI tests cover settings navigation, toggles, privacy information, reset confirmation, and cancellation.

### Completion metric

- Every app-owned preference is visible and changeable in Settings.
- Reset removes only documented local data.
- Destructive actions require explicit confirmation.

---

## P1-06: Widget or complication for the primary action

**Verified gaps:** GAP-WID-01, GAP-WID-02  
**Components:** WidgetKit extension, `AppleWatchWidget.swift`, `TimelineProvider.swift`, App Intents, deep-link router

### Expected behaviour

- Add a WidgetKit extension supporting appropriate watchOS accessory families.
- Surface the highest-value current status or launch action.
- Provide placeholder, snapshot, loaded, stale, and unavailable states.
- Deep-link to destination search, resume prompt, or active navigation as appropriate.
- Avoid exposing sensitive destination details on the watch face unless explicitly enabled.

### Test requirement

- Unit tests cover timeline generation for empty, active, stale, and unavailable data.
- Deep-link tests verify each supported URL or App Intent opens the correct app state.
- Snapshot tests cover supported widget families.

### Completion metric

- Every supported family renders without clipping.
- Widget interactions route to the intended screen.
- Timeline generation works without launching the main app.

---

## P1-07: Actionable notifications and background refresh

**Verified gaps:** GAP-NOT-01, GAP-NOT-02, GAP-BG-01  
**Components:** `NotificationManager.swift`, `BackgroundRefreshManager.swift`, Settings, deep-link router

### Expected behaviour

- Register only notification categories used by the product.
- Request notification permission contextually.
- Prevent duplicate notifications for the same event.
- Route notification actions to the relevant app screen.
- Schedule background refresh within watchOS limits.
- Surface permission and refresh status in Settings.
- Avoid using notifications as a substitute for active turn guidance.

### Test requirement

- Unit tests cover authorisation states, category registration, deduplication, scheduling, and deep-link payload parsing.
- Tests verify refresh completion is always reported to the system.

### Completion metric

- Duplicate event notifications are suppressed.
- Every notification action has a tested destination.
- Background handlers complete successfully on all code paths.

---

## P1-08: Accessibility and compact watch layout

**Verified gaps:** GAP-ACC-01, GAP-ACC-02, GAP-ACC-03, GAP-ACC-04, GAP-ACC-05  
**Components:** all interactive SwiftUI views

### Expected behaviour

- Add stable accessibility identifiers to critical controls.
- Provide VoiceOver labels, values, hints, and grouping where visual context is insufficient.
- Support Dynamic Type without clipping essential navigation instructions.
- Maintain minimum practical watchOS tap targets.
- Respect Reduce Motion and avoid motion-only communication.
- Ensure route status, distance, and error text are understandable without colour.

### Test requirement

- UI tests locate and operate primary controls through accessibility identifiers.
- Manual VoiceOver checklist covers search, route preview, active guidance, stop, retry, settings, and arrival.
- Layout tests cover supported watch sizes and accessibility text sizes.

### Completion metric

- The critical journey is completable with VoiceOver.
- No essential text truncates at required accessibility sizes.
- Every critical interactive control has a unique identifier and accessible name.

---

## P1-09: Destructive-action confirmation and consistent haptics

**Verified gap:** GAP-ACC-06  
**Components:** `HapticFeedback.swift`, stop navigation control, reset controls, arrival and failure feedback

### Expected behaviour

- Confirm stopping an active ride before discarding route state.
- Confirm local-data reset.
- Play haptics only for completed actions, warnings, navigation cues, and failures.
- Always pair haptics with visible or spoken feedback.
- Prevent duplicate haptics from repeated state updates.

### Test requirement

- UI tests cover confirmation, cancellation, and destructive completion.
- Unit tests verify one haptic event per qualifying state transition using an injectable haptic service.

### Completion metric

- No destructive action executes on a single accidental tap.
- Every haptic has equivalent accessible feedback.
- Duplicate state emissions do not produce repeated haptics.

---

## P1-10: Privacy manifest and location-retention policy

**Verified gaps:** GAP-PRV-01, GAP-PRV-03, GAP-PRV-04  
**Components:** `PrivacyInfo.xcprivacy`, Info.plist usage descriptions, privacy screen, persistence layer

### Expected behaviour

- Add a privacy manifest matching APIs and data access actually used.
- Document whether location data leaves the device.
- Persist no raw location trail unless explicitly required and disclosed.
- Clear transient location values when a trip ends.
- Align background-location declarations with actual product behaviour.

### Test requirement

- CI validation confirms the privacy manifest is included in the built product.
- Unit tests verify reset and trip completion clear retained location context.
- Release checklist compares capabilities, plist descriptions, privacy screen, and implementation.

### Completion metric

- Privacy declarations and implementation have no known mismatch.
- Raw travelled-location history is not persisted by default.
- App review privacy artefacts are present in the archive.

---

# P2: Diagnostics, performance, and release maturity

## P2-01: Privacy-safe structured logging

**Verified gaps:** GAP-DIAG-01, GAP-DIAG-02  
**Components:** `AppLogger.swift`, navigation, networking, persistence, sync, widgets, notifications

### Expected behaviour

- Use `os.Logger` categories for lifecycle, networking, navigation, persistence, sync, widgets, and notifications.
- Replace unstructured `print` calls.
- Record operation type, state, duration class, and non-sensitive failure category.
- Mark destination names, coordinates, routes, and user-entered search terms as private or omit them.
- Provide enough context to diagnose failures without reconstructing user movement.

### Test requirement

- Static check rejects `print(` in production Swift files.
- Unit tests verify error-to-category mapping.
- Manual privacy review samples logs from search, route, reroute, and failure flows.

### Completion metric

- Production code contains no direct print logging.
- Logs contain no plaintext coordinates, destination names, or search queries.
- Each recoverable failure emits one categorised diagnostic event.

---

## P2-02: Performance and energy baselines

**Verified gap:** GAP-DIAG-03  
**Components:** test targets, app launch, `NavigationModel.swift`, map rendering, background services

### Expected behaviour

- Add performance tests for launch and primary-screen state preparation.
- Measure route-screen rendering and state-transition latency using deterministic fakes.
- Cancel timers, searches, directions, and location work when no longer needed.
- Limit refresh frequency and avoid unnecessary map camera updates.
- Record a repeatable device and simulator profiling procedure.

### Test requirement

- XCTest performance cases establish baselines for launch and primary state transitions.
- Instruments checklist covers CPU, memory, location, network, and energy on a physical watch.
- Regression thresholds are documented in CI or the release checklist.

### Completion metric

- Performance tests produce stable baselines.
- No abandoned asynchronous work remains active after leaving its flow.
- Profiling reveals no sustained background activity after navigation stops.

---

## P2-03: Release automation and quality gates

**Verified gap:** GAP-ENG-02 and the absence of verified automated release controls  
**Components:** CI workflow, Xcode schemes, `README.md`, release checklist

### Expected behaviour

- Build all configured Apple platform targets in Debug and Release.
- Run unit and UI tests on supported simulator destinations.
- Enforce the repository's formatter or SwiftLint configuration.
- Validate privacy manifest inclusion and required usage descriptions.
- Document setup, supported watchOS version, capabilities, test commands, archive steps, and release checks.

### Test requirement

- CI is triggered for pull requests and the main branch.
- A deliberately failing unit test, lint violation, or build error blocks the gate.
- Release archive command is verified in the documented environment.

### Completion metric

- No change can merge while required build, test, lint, or privacy checks fail.
- A Release archive completes through the documented command.
- A new contributor can build and test using only the README instructions.

---

## P2-04: Search and destination-context polish

**Verified gaps:** GAP-REC-01, GAP-REC-02  
**Components:** `SearchView`, `RoutePreviewView`, `NavigationModel.swift`

### Expected behaviour

- Keep the last valid query visible when returning from route preview.
- Preserve search results where safe during transient failures.
- Provide a clear way to change destination from route preview.
- Avoid clearing context until a new operation succeeds or the user explicitly resets it.

### Test requirement

- Unit tests cover back navigation, failed route calculation, retry, and explicit reset.
- UI test verifies a user can change destination without retyping unnecessarily.

### Completion metric

- Search text is lost only after explicit reset or completed flow.
- Route failure returns the user to recoverable context.
- Destination replacement is possible in two interactions or fewer from preview.

---

# Delivery sequence

Implementation should proceed in this order to minimise rework:

1. **P0-03** service injection and asynchronous ownership.
2. **P0-01** deterministic state model.
3. **P0-05** reusable state components.
4. **P0-02** operation-specific retry.
5. **P0-04** location lifecycle.
6. **P0-06** arrival handling.
7. **P0-07** critical automated tests.
8. **P1-01 through P1-05** persistence, restoration, onboarding, and settings.
9. **P1-08 through P1-10** accessibility, confirmation, haptics, and privacy.
10. **P1-06 and P1-07** widgets, notifications, and background refresh.
11. **P2 items** diagnostics, performance, automation, and polish.

## Release gates

### Core reliability gate

All P0 items must be complete before a release candidate is created.

### Product readiness gate

P1-04, P1-05, P1-08, P1-09, and P1-10 must be complete before external distribution. Widget, notification, and offline restoration items may be feature-flagged only if their incomplete capabilities are absent from the shipped target and user-facing copy.

### Final release gate

- Debug and Release builds succeed.
- Required unit and UI tests pass.
- The critical navigation journey passes on a physical Apple Watch.
- VoiceOver and accessibility-size checks pass.
- Location stops after navigation.
- Privacy declarations match the archive.
- No open P0 defect remains.