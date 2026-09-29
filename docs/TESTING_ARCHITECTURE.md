# Testing Architecture & Reliability Harnesses

## 1. Overview
UltraNav test infrastructure is architected for **100% deterministic, hermetic, and fast execution** on local machines and CI environments without requiring physical Apple Watch hardware, real GPS signals, HealthKit authorizations, live Bluetooth peripherals, or external file systems.

```
TestAppContainer
      │
      ├── TestClock (Deterministic wall-clock)
      ├── TestMonotonicClock (Nanosecond monotonic time)
      ├── ManualTicker (Discrete tick generator)
      │
      ├── FakeLocationProvider (Controllable GPS stream & gates)
      ├── FakeWorkoutProvider (Controllable HealthKit workout & gates)
      ├── FakeSensorProvider (Controllable Bluetooth BLE streams & gates)
      ├── FakeRouteStore (In-memory sorted canonical route store)
      ├── FakeRouteImporter (Controllable GPX import & cancellation)
      ├── FakeHapticProvider (Recorded haptic pattern sequence)
      │
      ├── RideEngine (Lifecycle & tracking orchestration)
      ├── NavigationEngine (Matching, cues, off-route progression)
      ├── MetricsEngine (Sensor aggregation & freshness)
      ├── ClimbEngine (Elevation profile & climb progression)
      ├── RouteLibraryEngine (GPX import & catalog management)
      │
      ├── RideDataCoordinator (MainActor event fan-out)
      ├── RideLifecycleCoordinator (Transactional lifecycle orchestration)
      ├── RouteNavigationCoordinator (Active route coordination)
      └── RecoveryCoordinator (Failure recovery & degradation policies)
```

---

## 2. Directory Structure & Organization

```
UltraNavTests/
├── Support/
│   ├── Async/
│   │   ├── OperationGate.swift             # Thread-safe suspension gate for race tests
│   │   ├── ControlledAsyncStream.swift     # Explicit item injection & termination
│   │   ├── AsyncTestWaiter.swift           # Bounded condition polling
│   │   ├── AsyncSequenceRecorder.swift     # Arbitrary AsyncSequence recording
│   │   ├── TestTimeout.swift               # Bounded safety timeout execution
│   │   ├── Eventually.swift                # Cooperative task-yielding condition helper
│   │   └── TaskLeakDetector.swift          # Validates 0 abandoned tasks remain
│   │
│   ├── Time/
│   │   ├── TestClock.swift                 # Thread-safe controllable Date clock
│   │   ├── TestMonotonicClock.swift        # Controllable MonotonicInstant clock
│   │   ├── ManualTicker.swift              # Discrete non-timer tick generator
│   │   ├── TestSleeper.swift               # Zero-delay fast-forward sleep replacement
│   │   └── TestDates.swift                 # Deterministic timestamp constants
│   │
│   ├── Recorders/
│   │   ├── SnapshotRecorder.swift          # Generic actor capturing engine snapshots
│   │   ├── EventRecorder.swift             # Generic actor capturing async stream events
│   │   ├── TransitionRecorder.swift        # State machine transition history
│   │   ├── FailureRecorderSpy.swift        # Failure reporting & recovery spy
│   │   └── HapticRecorder.swift            # Haptic pattern sequence recorder
│   │
│   ├── Fixtures/
│   │   ├── TestIDs.swift                   # Fixed stable domain identifiers
│   │   ├── LocationFixture.swift           # Accurate, stationary, degraded GPS samples
│   │   ├── RideFixture.swift               # Idle, active, paused, finished snapshots
│   │   ├── SensorFixture.swift             # HR, power, cadence, speed observations
│   │   ├── MetricFixture.swift             # Metric samples, fresh & stale snapshots
│   │   ├── RouteFixture.swift              # Straight, turn, climbing, loop routes
│   │   ├── NavigationFixture.swift         # Route matches, cues, navigation snapshots
│   │   ├── ClimbFixture.swift              # Climb segments, progress, climb snapshots
│   │   └── FailureFixture.swift            # Failure reports, contexts, severity levels
│   │
│   ├── Assertions/
│   │   ├── RideAssertions.swift            # assertRideActive, assertRidePaused, etc.
│   │   ├── NavigationAssertions.swift      # assertNavigationNavigating, assertOffRoute
│   │   ├── MetricsAssertions.swift         # assertMetricsSpeed, assertMetricsPower
│   │   ├── ClimbAssertions.swift           # assertClimbingActive, assertClimbingInactive
│   │   ├── EventAssertions.swift           # XCTAssertEqualEvents call order validation
│   │   └── DiagnosticAssertions.swift      # Observability event & PII assertions
│   │
│   └── Builders/
│       ├── TestAppContainerBuilder.swift   # Full application dependency graph builder
│       ├── RideEngineBuilder.swift         # Fluent builder for RideEngine
│       ├── NavigationEngineBuilder.swift   # Fluent builder for NavigationEngine
│       ├── MetricsEngineBuilder.swift      # Fluent builder for MetricsEngine
│       └── ClimbEngineBuilder.swift        # Fluent builder for ClimbEngine
│
├── TestDoubles/
│   ├── FakeLocationProvider.swift          # Call enum, startGate, status stubs
│   ├── FakeWorkoutProvider.swift           # Call enum, startGate, finishGate
│   ├── FakeSensorProvider.swift            # Call enum, connectGate, disconnect history
│   ├── FakeRouteStore.swift                # Sorted summaries, loadGate, failures
│   ├── FakeRouteImporter.swift             # RouteImporting double with OperationGate
│   ├── FakeHapticProvider.swift            # HapticProviding double with pattern log
│   ├── FakeSettingsProvider.swift          # AppConfiguration double
│   ├── InMemoryRouteFileSystem.swift       # RouteFileSystemProviding in-memory actor
│   └── FakeRecoveryPolicy.swift            # Recovery recommendation test double
│
├── Harnesses/
│   ├── RideEngineHarness.swift             # Isolated RideEngine harness
│   ├── NavigationEngineHarness.swift       # Isolated NavigationEngine harness
│   ├── MetricsEngineHarness.swift          # Isolated MetricsEngine harness
│   ├── ClimbEngineHarness.swift            # Isolated ClimbEngine harness
│   ├── RoutePipelineHarness.swift          # Route storage & import pipeline harness
│   ├── RideDataCoordinatorHarness.swift    # Coordinator event fan-out harness
│   └── UltraNavIntegrationHarness.swift    # Full application integration harness
│
└── Integration/
    ├── CompleteRideLifecycleIntegrationTests.swift
    ├── DegradedOperationIntegrationTests.swift
    ├── RecoveryIntegrationTests.swift
    └── CancellationAndRaceIntegrationTests.swift
```

---

## 3. Reliability Principles & Verification
1. **Strict Concurrency Safety:** All test doubles and recorders use actors or `NSLock` locks to guarantee zero data races under Swift 6.
2. **Explicit Time Progression:** Clocks advance only when commanded via `clock.advance(by:)` or `ticker.tick()`.
3. **Cooperative Task Yielding:** Asynchronous assertions use `eventually()` and `Task.yield()` with short safety deadlines (1–3 seconds).
4. **Clean Teardown:** Every harness implements `shutdown()` to terminate stream continuations and cancel active background tasks.
