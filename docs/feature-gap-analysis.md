# UltraNav Feature-Gap Analysis

This assessment records only gaps confirmed against the repository audit completed on 28 September 2026. It covers product behaviour, watchOS integration, reliability, accessibility, privacy, and recovery. Implementation sizes are relative estimates: **S** for a localised change, **M** for a multi-file feature, and **L** for a new architectural capability or target.

## Summary

| Area | Current repository state | Confirmed gaps | Highest impact |
|---|---|---:|---|
| Onboarding | App opens directly into search and requests location | 2 | Permission requests lack context |
| Empty states | Passive prompt doubles as initial and zero-result state | 2 | Users cannot distinguish no results from initial state |
| Loading and errors | Search has loading feedback; route calculation and rerouting do not | 5 | Generic retry does not retry the failed operation |
| Settings | No settings screen or persisted preferences | 3 | Users cannot review permissions or control behaviour |
| Offline behaviour | MapKit-only live requests with no cache or reachability state | 4 | Existing work is lost when connectivity fails |
| Notifications | No notification manager, categories, or permission flow | 2 | No actionable off-wrist or background feedback |
| Complications/widgets | No WidgetKit target or App Intent | 2 | Primary app status/action is unavailable from the watch face |
| Background refresh | Background location is enabled directly; no refresh manager | 3 | Behaviour and energy use are not controlled |
| Accessibility | No verified accessibility audit or UI automation identifiers | 6 | Critical controls may be ambiguous to VoiceOver users |
| Privacy | Location descriptions exist, but no privacy manifest or privacy surface | 4 | Data practices and required-reason APIs are not documented |
| Analytics/diagnostics | No structured logging or product analytics | 3 | Failures cannot be diagnosed without exposing data |
| Interrupted actions | Navigation, search, and route selection are memory-only | 4 | Relaunch and generic errors discard user context |

## 1. Onboarding and permission sequencing

### GAP-ONB-01: No first-launch onboarding

- **Evidence:** `UltraNavApp` immediately presents `ContentView`; `ContentView` begins with destination search.
- **Affected files:** `UltraNav/UltraNavApp.swift`, `UltraNav/ContentView.swift`; new `UltraNav/Views/OnboardingView.swift`; persistence component for completion status.
- **User impact:** First-time users receive no explanation of cycling navigation, expected network use, location dependence, background behaviour, or safety limitations.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. First launch presents a concise, wrist-readable onboarding flow before search.
  2. The flow explains destination search, cycling-route guidance, GPS/network requirements, and safe use.
  3. Completion is persisted and onboarding does not reappear on every launch.
  4. Settings provides an action to replay onboarding.
  5. VoiceOver can read the flow in a logical order.

### GAP-ONB-02: Location permission is requested without an in-app rationale

- **Evidence:** A root view task calls `requestLocationAccess()` when the initial screen appears.
- **Affected files:** `UltraNav/ContentView.swift`, `UltraNav/NavigationModel.swift`, `UltraNav/Info.plist`; new onboarding or permission-rationale view.
- **User impact:** Users may deny a sensitive permission because its immediate purpose and background implications are not explained.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. The system prompt appears only after the user acknowledges a location rationale or starts a feature that requires location.
  2. The rationale explains why precise location is required.
  3. Denied and restricted states show distinct guidance.
  4. Denied users receive a working route to the relevant system settings where watchOS permits it.
  5. The `Info.plist` descriptions match actual foreground and background behaviour.

## 2. Empty states

### GAP-EMP-01: Zero-result search has no dedicated state

- **Evidence:** A successful search stores an empty results array and returns to `idle`, which shows the same passive prompt used before any search.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`; new shared `EmptyStateView.swift`.
- **User impact:** Users cannot tell whether the search completed, failed silently, or has not run.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. A completed search with no matches enters an explicit empty state.
  2. The state includes the submitted query.
  3. It offers clear actions to edit or retry the search.
  4. The state is distinct from initial idle and failure states.
  5. A unit test verifies the empty transition.

### GAP-EMP-02: Missing GPS fix has no waiting state

- **Evidence:** Search can proceed without current location, while destination selection fails if `currentLocation` is absent.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`; new shared loading/status component.
- **User impact:** A user can select a destination and encounter an avoidable error while location acquisition is still in progress.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. The UI distinguishes waiting for GPS from permission denial and GPS failure.
  2. Route calculation waits for a valid fix or offers cancellation.
  3. A bounded wait transitions to a recoverable failure state.
  4. VoiceOver announces meaningful status changes without repeated interruptions.

## 3. Loading, success, and error states

### GAP-STATE-01: Route calculation lacks a visible loading state

- **Evidence:** Destination selection starts asynchronous directions work without a dedicated state.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`; new `LoadingView.swift`.
- **User impact:** The watch can appear unresponsive, encouraging duplicate taps and duplicate route requests.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Route calculation enters an explicit loading state.
  2. The selected destination remains visible.
  3. Duplicate requests are prevented.
  4. The operation can be cancelled when appropriate.
  5. Success and failure leave the loading state deterministically.

### GAP-STATE-02: Rerouting has no visible status

- **Evidence:** Automatic rerouting runs in a retained task while the state generally remains `navigating`.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** Guidance may be stale while the user has no indication that recovery is underway.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Navigation exposes a non-blocking rerouting status.
  2. Existing guidance is clearly marked as stale while recalculation runs.
  3. Success replaces the route and announces confirmation.
  4. Failure preserves the previous route where safe and offers retry or stop.
  5. Cancellation does not emit success haptics or failure UI.

### GAP-STATE-03: Error representation is an untyped string

- **Evidence:** `NavigationModel.State.error(String)` combines permission, GPS, search, route, and reroute failures.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`; new shared `ErrorStateView.swift` and `RetryButton.swift`.
- **User impact:** The UI cannot select recovery actions, severity, or context reliably.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Errors use a typed domain that identifies the failed operation and recoverability.
  2. User-facing copy is mapped separately from underlying errors.
  3. Technical details and location values are not exposed in UI or logs.
  4. Unit tests cover each error category and recovery action.

### GAP-STATE-04: Generic retry does not retry the failed operation

- **Evidence:** “Try Again” returns to idle and requests location access regardless of whether search, directions, GPS, or permission failed.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** Search text, selected destination, and navigation context are lost, increasing effort and making reroute failures especially disruptive.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Search failures retry the same query.
  2. Route failures retry the same source and destination after validating location.
  3. Permission failures show permission-specific recovery.
  4. Reroute failures preserve active navigation and retry rerouting.
  5. Retry actions are idempotent and cannot create duplicate requests.

### GAP-STATE-05: Search and initial route tasks cannot be cancelled

- **Evidence:** Only the reroute task is retained and cancelled.
- **Affected files:** `UltraNav/NavigationModel.swift`.
- **User impact:** Older responses can overwrite newer intent, and abandoned work consumes energy and network resources.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Search and route tasks are retained.
  2. A new request cancels the obsolete request.
  3. Cancelled responses never mutate visible state.
  4. Tasks are cancelled when their owning screen disappears or the session resets.
  5. Unit tests cover rapid replacement and cancellation.

## 4. Settings

### GAP-SET-01: No settings screen

- **Evidence:** No settings view or navigation path exists.
- **Affected files:** `UltraNav/ContentView.swift`; new `UltraNav/Views/SettingsView.swift`.
- **User impact:** Users cannot review app behaviour, permission status, privacy information, or support details.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Search provides a discoverable settings entry.
  2. Settings displays location, notification, and background-refresh status.
  3. Privacy information and app version are available.
  4. Controls are usable with VoiceOver and Dynamic Type.
  5. Settings changes persist across relaunches.

### GAP-SET-02: No user controls for notification or refresh behaviour

- **Evidence:** No notification or background-refresh services or settings exist.
- **Affected files:** new `SettingsView.swift`, `NotificationManager.swift`, `BackgroundRefreshManager.swift`, and preferences persistence.
- **User impact:** Future watchOS-native features would be enabled without transparent user control.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Settings exposes only controls backed by implemented behaviour.
  2. App preferences remain distinct from system authorisation status.
  3. Disabled preferences prevent scheduling.
  4. Revoked system permission is reflected accurately on return to the app.

### GAP-SET-03: No reset action for local app state

- **Evidence:** There is no persisted settings model and no reset workflow.
- **Affected files:** new `SettingsView.swift`, cache/preferences components.
- **User impact:** Once persistence is introduced, users need a transparent way to clear recent destinations, cached content, and onboarding state.
- **Implementation size:** S after persistence exists.
- **Acceptance criteria:**
  1. A destructive reset requires confirmation.
  2. The confirmation names the categories removed.
  3. Reset clears only application-owned local data.
  4. Completion receives visible and haptic feedback.
  5. Reset remains accessible without requiring sign-in.

## 5. Offline behaviour and persistence

### GAP-OFF-01: No cached user-visible data

- **Evidence:** All search, route, and navigation state is memory-only.
- **Affected files:** `UltraNav/NavigationModel.swift`; new `UltraNav/Services/AppCache.swift`.
- **User impact:** Relaunch or transient connectivity loss removes useful recent context.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. The last successful user-visible destination and route summary are stored locally where platform types permit safe serialisation.
  2. Cached content loads before a live refresh.
  3. Stale content is visibly labelled with its age.
  4. Cache expiry is deterministic and unit tested.
  5. Sensitive location data has a documented retention limit and reset path.

### GAP-OFF-02: No connectivity-aware state

- **Evidence:** MapKit failures are converted directly into generic connectivity-oriented messages without reachability context.
- **Affected files:** `UltraNav/NavigationModel.swift`; new connectivity abstraction or sync coordinator.
- **User impact:** Users cannot distinguish offline status, service failure, and an invalid search.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. The app reports offline status without claiming every MapKit failure is connectivity-related.
  2. Available cached content remains usable.
  3. Live actions clearly identify that connectivity is required.
  4. Reconnection triggers one bounded refresh rather than duplicate requests.

### GAP-OFF-03: No offline-safe mutation queue

- **Evidence:** No persistence or synchronisation coordinator exists.
- **Affected files:** new `UltraNav/Services/SyncCoordinator.swift` and persistence models.
- **User impact:** Future favourites, settings-backed actions, or trip completion events could be silently lost.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. Only idempotent, safe operations are queued.
  2. Queue entries persist across launch.
  3. Retries use bounded backoff.
  4. Conflicts have deterministic resolution.
  5. No raw location history is queued unless explicitly required and disclosed.

### GAP-OFF-04: Interrupted navigation cannot be restored

- **Evidence:** Active route, destination, and progress exist only in memory.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/UltraNavApp.swift`; new cache/session model.
- **User impact:** App termination or restart during a ride discards guidance.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. A recent interrupted session is detected at launch.
  2. The user can resume or discard it.
  3. Resume validates route age, destination, current location, and network requirements.
  4. Invalid sessions fail safely with a clear explanation.
  5. Discard removes stored session data.

## 6. Notifications

### GAP-NOT-01: No notification capability or manager

- **Evidence:** No UserNotifications integration, categories, requests, or notification-specific settings exist.
- **Affected files:** new `UltraNav/Services/NotificationManager.swift`, `SettingsView.swift`, project capabilities and metadata where required.
- **User impact:** The app cannot provide controlled actionable reminders or relevant background feedback.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Permission is requested only after the user enables a notification-backed feature.
  2. Required categories are registered once.
  3. Duplicate notifications are prevented.
  4. Notification content contains no sensitive destination or precise-location data on a locked device by default.
  5. Settings reflects current system permission.

### GAP-NOT-02: No notification deep-link handling

- **Evidence:** The app has no deep-link router or notification-response handler.
- **Affected files:** `UltraNav/UltraNavApp.swift`, `UltraNav/ContentView.swift`; new notification manager and route model.
- **User impact:** Notification actions cannot open the relevant status or recovery screen.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Every registered action maps to a valid in-app destination.
  2. Cold-start and warm-start handling produce the same result.
  3. Invalid or stale payloads open a safe fallback.
  4. UI tests cover supported deep links.

## 7. Complications and widgets

### GAP-WID-01: No WidgetKit or complication target

- **Evidence:** The Xcode project contains only the watchOS application target.
- **Affected files:** `UltraNav.xcodeproj/project.pbxproj`; new WidgetKit extension, `AppleWatchWidget.swift`, and timeline provider.
- **User impact:** Users cannot see useful app status or launch the primary action from the watch face or Smart Stack.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. A WidgetKit extension builds for supported accessory families.
  2. Placeholder, snapshot, and timeline states are implemented.
  3. Empty and stale data are represented honestly.
  4. Widget data is minimal and privacy-safe.
  5. The app and widget targets build in Debug and Release.

### GAP-WID-02: No App Intent or widget deep link

- **Evidence:** No App Intent definitions or navigation router exist.
- **Affected files:** new App Intent files, widget files, `UltraNavApp.swift`, `ContentView.swift`, and shared route definitions.
- **User impact:** A widget cannot launch destination search or resume an eligible navigation session directly.
- **Implementation size:** M after the widget target exists.
- **Acceptance criteria:**
  1. The primary widget interaction opens the intended screen.
  2. Invalid session state falls back to search.
  3. Deep links work from terminated and active app states.
  4. UI tests verify routing.

## 8. Background refresh and location lifecycle

### GAP-BG-01: No background refresh manager

- **Evidence:** No WatchKit background refresh scheduling or coordinator exists.
- **Affected files:** new `UltraNav/Services/BackgroundRefreshManager.swift`, `UltraNav/UltraNavApp.swift`, settings and project configuration.
- **User impact:** Refresh behaviour cannot be scheduled, deduplicated, measured, or disabled predictably.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. Refresh is scheduled only for a documented user-visible purpose.
  2. Duplicate pending refreshes are avoided.
  3. Work completes within watchOS constraints.
  4. Failures use bounded rescheduling.
  5. Settings disables future scheduling.

### GAP-BG-02: Location updates continue after navigation stops

- **Evidence:** `stopNavigation()` resets route state but does not call `stopUpdatingLocation()`.
- **Affected files:** `UltraNav/NavigationModel.swift`.
- **User impact:** Unnecessary GPS activity can increase battery use and privacy exposure.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Continuous location updates stop when navigation ends and no foreground feature requires them.
  2. Search uses a bounded one-shot location request or an explicitly managed foreground update.
  3. Starting or resuming navigation restarts the required update mode.
  4. Tests verify lifecycle transitions through an injected location-service abstraction.

### GAP-BG-03: Background-location configuration is not validated end to end

- **Evidence:** `allowsBackgroundLocationUpdates` is enabled while the entitlement dictionary is empty.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/Info.plist`, `UltraNav/UltraNav.entitlements`, project capabilities.
- **User impact:** Device behaviour may differ from simulator expectations, and permission copy may not match actual use.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Background location is enabled only if required for active navigation.
  2. Project capabilities and plist metadata match the implementation.
  3. Background behaviour is verified on a physical watch.
  4. Ending navigation ends background location use.
  5. Privacy documentation explains the behaviour.

## 9. Accessibility and watchOS interaction

### GAP-ACC-01: No accessibility identifiers for critical controls

- **Evidence:** No verified identifiers exist and there is no UI-test target.
- **Affected files:** `UltraNav/ContentView.swift` and future shared UI components.
- **User impact:** Critical journeys cannot be reliably automated, and assistive metadata is harder to audit.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Search input, result rows, start, stop, retry, settings, and map-navigation controls have stable identifiers.
  2. Identifiers are unique per screen.
  3. UI tests use identifiers rather than visible copy.

### GAP-ACC-02: VoiceOver labels, values, hints, and grouping are not verified

- **Evidence:** Views rely mainly on default SwiftUI semantics.
- **Affected files:** `UltraNav/ContentView.swift`.
- **User impact:** Icon-only controls, route metrics, turn symbols, and map annotations may be ambiguous or excessively verbose.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Icon-only controls have meaningful labels and destructive-action hints.
  2. Guidance exposes instruction and distance as a coherent element.
  3. Route duration and distance have understandable values.
  4. Decorative imagery is hidden.
  5. Manual VoiceOver traversal follows visual priority.

### GAP-ACC-03: Dynamic Type and compact-screen layout are not verified

- **Evidence:** No accessibility or snapshot tests exist.
- **Affected files:** `UltraNav/ContentView.swift`.
- **User impact:** Instructions and controls may clip at larger accessibility text sizes.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Primary actions remain visible at supported accessibility sizes.
  2. Guidance text wraps or scrolls without overlap.
  3. No essential content is truncated without an accessible alternative.
  4. Layout is verified on the smallest and largest supported watch displays.

### GAP-ACC-04: Tap-target sizing is not systematically enforced

- **Evidence:** No shared control style or accessibility audit exists.
- **Affected files:** `UltraNav/ContentView.swift`; future shared UI styles.
- **User impact:** Compact or icon-only controls may be difficult for users with motor impairments.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Primary interactive controls meet watchOS hit-area guidance.
  2. Adjacent destructive and non-destructive actions have adequate separation.
  3. The visual size may remain compact while the hit area is expanded safely.

### GAP-ACC-05: Reduced Motion behaviour is not defined

- **Evidence:** Camera movement and state transitions do not consult `accessibilityReduceMotion`.
- **Affected files:** `UltraNav/ContentView.swift`, `UltraNav/NavigationModel.swift`.
- **User impact:** Frequent map-camera movement may be uncomfortable or distracting.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Reduced Motion suppresses non-essential animation.
  2. Map-camera updates avoid decorative transitions.
  3. Functional state changes remain clear without motion.

### GAP-ACC-06: Destructive stop action has no confirmation

- **Evidence:** Stop navigation immediately clears the session.
- **Affected files:** `UltraNav/ContentView.swift`, `UltraNav/NavigationModel.swift`.
- **User impact:** An accidental tap ends guidance and loses route context.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. Stop requires an accessible confirmation.
  2. Confirmation identifies that active guidance will end.
  3. Cancel preserves all session state.
  4. Confirmed stop provides visible text plus haptic feedback.

## 10. Privacy

### GAP-PRV-01: No privacy manifest

- **Evidence:** No `PrivacyInfo.xcprivacy` is present.
- **Affected files:** new `UltraNav/PrivacyInfo.xcprivacy`; Xcode project resources.
- **User impact:** Required-reason API and collected-data declarations cannot be reviewed from the repository.
- **Implementation size:** S to M, depending on API inventory.
- **Acceptance criteria:**
  1. A privacy manifest is included in the application target.
  2. Required-reason API declarations match actual usage.
  3. Collected-data declarations are accurate and minimal.
  4. Release validation reports no unexplained privacy-manifest issues.

### GAP-PRV-02: No in-app privacy information

- **Evidence:** No onboarding or settings screen exposes location and retention practices.
- **Affected files:** new `OnboardingView.swift`, `SettingsView.swift`, privacy copy resource.
- **User impact:** Users cannot understand what location data is used, retained, or shared.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. The app explains that MapKit and Core Location support search and routing.
  2. Local retention and reset behaviour are stated accurately.
  3. Copy does not claim offline or server behaviour that is not implemented.
  4. Privacy information is accessible from settings.

### GAP-PRV-03: Location retention policy is undefined

- **Evidence:** Current data is memory-only, while planned caching and interrupted-session recovery will introduce durable location-related data.
- **Affected files:** future `AppCache.swift`, session models, settings/privacy copy.
- **User impact:** New persistence could retain sensitive data longer than users expect.
- **Implementation size:** M as part of persistence.
- **Acceptance criteria:**
  1. Each stored location-related field has a documented purpose and expiry.
  2. Precise raw location history is not stored unless required.
  3. Reset removes retained location-related data.
  4. Tests verify expiry and deletion.

### GAP-PRV-04: Background-location disclosure may not match implementation

- **Evidence:** Background updates are enabled in code while capability and metadata validation remain incomplete.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/Info.plist`, entitlements, onboarding and settings.
- **User impact:** Users may not understand when location continues to be used.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Background use occurs only during active navigation.
  2. Permission copy describes the precise purpose.
  3. Active navigation clearly indicates ongoing location use.
  4. Stop immediately ends unnecessary background tracking.

## 11. Analytics and diagnostics

### GAP-DIAG-01: No structured logging

- **Evidence:** No `os.Logger` abstraction or category-based diagnostic layer exists.
- **Affected files:** new `UltraNav/Services/AppLogger.swift`; `UltraNavApp.swift`, `NavigationModel.swift`, future services.
- **User impact:** Search, route, GPS, and reroute failures are difficult to diagnose.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Lifecycle, location, routing, persistence, sync, widget, and notification events use explicit categories.
  2. Logs contain non-sensitive operation context.
  3. Destination names, search text, precise coordinates, and route geometry are private or omitted.
  4. Direct `print` calls are prohibited by review or linting.

### GAP-DIAG-02: No privacy-safe failure metrics

- **Evidence:** No analytics framework, event schema, or opt-in policy exists.
- **Affected files:** future diagnostics or analytics service, settings/privacy documentation.
- **User impact:** The team cannot quantify reliability or prioritise common failures.
- **Implementation size:** L if product analytics is adopted.
- **Acceptance criteria:**
  1. A written event schema defines purpose, fields, retention, and ownership.
  2. Events never contain destination text, coordinates, or route geometry.
  3. User consent and applicable platform requirements are satisfied.
  4. The app functions fully when analytics is unavailable or disabled.
  5. If analytics is not justified, the decision to omit it is documented.

### GAP-DIAG-03: No measurable performance or energy telemetry

- **Evidence:** No XCTest performance tests, signposts, or Instruments baseline exists.
- **Affected files:** future test target, `AppLogger.swift`, launch and navigation code.
- **User impact:** Regressions in launch time, GPS use, request duplication, and battery consumption can ship undetected.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Launch and primary-screen loading have repeatable performance tests.
  2. Search, directions, and rerouting have signposted durations without sensitive payloads.
  3. A physical-watch energy baseline covers active and stopped navigation.
  4. Release criteria define acceptable regression thresholds.

## 12. Recovery from interrupted actions

### GAP-REC-01: Search context is discarded on failure recovery

- **Evidence:** Generic retry returns to idle and does not directly retry the prior query.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** Users must re-enter destination text on a small watch display.
- **Implementation size:** S.
- **Acceptance criteria:**
  1. The failed query remains editable.
  2. Retry submits the same query exactly once.
  3. Cancel returns to search without clearing user input unless requested.

### GAP-REC-02: Route-selection context is discarded on failure

- **Evidence:** Directions failure enters the generic error state without operation-specific restoration.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** Users must repeat search and destination selection after transient route failures.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. The selected destination is retained for recoverable failures.
  2. Retry recalculates from the latest valid location.
  3. Change Destination returns to results or search.
  4. Stale asynchronous results cannot replace a newer selection.

### GAP-REC-03: Reroute failure replaces active guidance with a generic error

- **Evidence:** A failed automatic reroute enters `error(String)`.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** A transient reroute failure removes the navigation UI when the previous route may still be useful.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. The previous route remains visible after reroute failure.
  2. Guidance is marked potentially stale.
  3. Retry reroutes from the current location.
  4. Stop remains available.
  5. Failure feedback supplements, rather than replaces, accessible text.

### GAP-REC-04: No arrival or completed-trip state

- **Evidence:** Navigation supports start and stop but has no arrival detection or completion transition.
- **Affected files:** `UltraNav/NavigationModel.swift`, `UltraNav/ContentView.swift`.
- **User impact:** Guidance may continue at the destination, with no clear completion or session cleanup.
- **Implementation size:** M.
- **Acceptance criteria:**
  1. Arrival uses a documented distance and accuracy rule.
  2. The app presents an explicit completed state.
  3. Completion stops unnecessary location updates and reroute work.
  4. Visible and haptic feedback confirm arrival.
  5. False arrival is avoided when location accuracy is insufficient.

## Cross-cutting engineering gaps

### GAP-ENG-01: Platform services are not injectable

- **Evidence:** `NavigationModel` constructs and directly uses Core Location, MapKit, and WatchKit services.
- **Affected files:** `UltraNav/NavigationModel.swift`; new service protocols and adapters.
- **User impact:** Reliability behaviour cannot be tested deterministically, increasing regression risk.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. Location, search, directions, haptics, persistence, and clock behaviour have injectable boundaries.
  2. Production adapters preserve current behaviour.
  3. Unit tests can simulate permission, GPS, empty search, route failure, cancellation, and rerouting.
  4. UI state remains main-actor isolated.

### GAP-ENG-02: No automated test targets

- **Evidence:** The project contains no unit-test or UI-test target.
- **Affected files:** `UltraNav.xcodeproj/project.pbxproj`; new unit and UI test directories.
- **User impact:** Critical journeys and failure recovery have no automated regression protection.
- **Implementation size:** L.
- **Acceptance criteria:**
  1. Unit and UI test targets build for watchOS Simulator.
  2. State transitions, empty results, cancellation, retry, interruption recovery, and arrival are covered.
  3. UI tests cover first launch, primary action, failure/retry, settings, and deep links.
  4. Tests run through a documented command.

## Measurement baseline for implementation

A gap is considered closed only when:

1. Its acceptance criteria are implemented.
2. A targeted automated test exists where the behaviour is deterministic.
3. Accessibility labels and identifiers are added for changed interactive UI.
4. New persistence has expiry and deletion tests.
5. New background, notification, widget, or location behaviour has matching privacy and settings documentation.
6. The watchOS Simulator Debug build continues to succeed.
7. Device-only behaviour is explicitly validated on physical Apple Watch hardware before release.