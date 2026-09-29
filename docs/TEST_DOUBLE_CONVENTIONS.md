# Test Double & Fixture Conventions

## 1. Test Double Classification

| Type | Definition | Example in UltraNav |
|---|---|---|
| **Fake** | Working in-memory implementation conforming to protocol | `FakeLocationProvider`, `FakeWorkoutProvider`, `FakeRouteStore` |
| **Spy** | Captures calls, parameters, and invocation order | `FailureRecorderSpy`, `calls` array in fake services |
| **Stub** | Returns canned responses or configured failures | `stubbedAuthorizationStatus`, `startFailure` |
| **Recorder** | Actor collecting streaming snapshots or events | `SnapshotRecorder<RideSnapshot>`, `EventRecorder<SensorServiceEvent>` |
| **Gate** | Controlled synchronization gate for async operations | `OperationGate` |
| **Fixture** | Immutable, deterministic domain models with explicit values | `LocationFixture`, `RouteFixture`, `MetricFixture` |
| **Harness** | Encapsulated system-under-test with controllable doubles | `UltraNavIntegrationHarness`, `RideEngineHarness` |

---

## 2. Standard Fake Service Conventions
Every fake service adheres to the following standard controls:

```swift
actor FakeService: ServiceProtocol {
    // 1. Event stream channel
    nonisolated let events: AsyncStream<ServiceEvent>

    // 2. Call sequence recording
    enum Call: Equatable, Sendable { case op1, op2(Param) }
    private(set) var calls: [Call] = []

    // 3. Stubbed status
    var stubbedStatus: ServiceStatus = .authorized

    // 4. Configured failures
    var nextFailure: ServiceFailure?

    // 5. Operation gates for partial-start & race tests
    var operationGate: OperationGate?

    // 6. Reset
    func clear() { ... }
}
```

---

## 3. Fixture Best Practices
- **Never use random UUIDs** in baseline test scenarios; use `TestIDs.routeAlpha`, `TestIDs.heartRateSensor`.
- **Never use `Date()`**; use `TestDates.rideStart` (`1_700_000_000` Unix timestamp).
- **Explicit Units:** All coordinates, distances (meters), speeds (m/s), power (watts), elevation (meters) are explicitly named.
