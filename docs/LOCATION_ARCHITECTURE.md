# Location Architecture & Service Boundary (Phase 1E)

## Overview

In UltraNav, **all CoreLocation framework interactions** (`CLLocationManager`, `CLLocation`, `CLAuthorizationStatus`, `CLError`) are encapsulated strictly behind the `LocationProviding` protocol boundary inside `LocationService`.

```
CoreLocation (CLLocationManager)
             │
             ▼
CoreLocationDelegateBridge
             │
             ▼
LocationService (Lifecycle & Authorization)
             │
             ▼ (CoreLocationSampleConverter)
LocationServiceEvent (.locationReceived(LocationSample))
             │
             ▼
RideEngine / NavigationEngine
```

---

## Key Invariants

1. **Zero Framework Leaks**: Domain models and computation engines (`RideEngine`, `NavigationEngine`, `MetricsEngine`, `ClimbEngine`) never import `CoreLocation` or receive `CLLocation` instances. They consume pure, Sendable `LocationSample` structs.
2. **Single Production Manager**: `LocationService` is the single production owner of `CLLocationManager`.
3. **Structured Normalization vs. Ride Filtering**:
   - `CoreLocationSampleConverter` validates structural invariants (geographic bounds, finite values, non-negative speed/course clipping to nil).
   - GPS quality filtering (accuracy cutoff, velocity spikes, outlier rejection) is intentionally deferred to **Phase 3 (Location & Sensor Fusion)**.
4. **Idempotent Lifecycle**: `startUpdates()` and `stopUpdates()` handle redundant calls safely without throwing or duplicating platform operations.
5. **Recoverable Error Handling**: Transient failures (`CLError.locationUnknown`) emit `.failed(.updatesUnavailable)` without killing the location session, allowing subsequent accurate samples to seamlessly continue the ride.

---

## Authorization State Flow

```
User Action: Start Ride
           │
           ▼
LocationService.requestAuthorization()
           │
           ├─► .authorized: proceed to start updates
           ├─► .denied / .restricted: throw LocationServiceFailure
           └─► .notDetermined: prompt system dialog
```
