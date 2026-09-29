# UltraNav Event Flow & Stream Fan-Out Architecture

## 1. Single Consumer Fan-Out Pattern
Because `AsyncStream` is single-consumer by design, platform services emit a single event stream consumed solely by `RideDataCoordinator`. `RideDataCoordinator` then synchronously and concurrently dispatches domain events to the appropriate engines.

```mermaid
flowchart TD
    subgraph Platform Services
        LS[LocationService]
        WS[HealthKitService]
        BS[BluetoothService]
    end

    subgraph Coordinator Layer
        RDC[RideDataCoordinator]
    end

    subgraph Domain Engines
        RE[RideEngine]
        ME[MetricsEngine]
        NE[NavigationEngine]
        CE[ClimbEngine]
    end

    LS -- LocationServiceEvent --> RDC
    WS -- WorkoutServiceEvent --> RDC
    BS -- SensorServiceEvent --> RDC

    RDC -- Location / Workout / Sensor Events --> RE
    RDC -- LocationSample / WorkoutMetric / SensorSample --> ME
    RDC -- LocationSample --> NE
    NE -- NavigationSnapshot (Progress) --> RNC[RouteNavigationCoordinator]
    RNC -- distanceAlongRouteMeters --> CE
```

---

## 2. Notification & Haptic Feedback Flow

```mermaid
flowchart LR
    NE[NavigationEngine] -- NavigationNotification --> NNC[NavigationNotificationCoordinator]
    CE[ClimbEngine] -- ClimbNotification --> NNC
    NNC -- HapticPattern --> HP[HapticProviding / WatchHapticService]
    HP --> Hardware[WKInterfaceDevice]
```

- **Turn Approaching / Immediate**: Haptic pulse alerts cyclist before and at turns.
- **Off Route / Route Rejoined**: Distinct alert vibrations warn of deviations and confirm rejoining.
- **Climb Events**: Alerts for approaching climb, climb start, and summit reach.
