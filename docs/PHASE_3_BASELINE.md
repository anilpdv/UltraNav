# Phase 3 Baseline Audit

**Date**: 2026-09-29  
**Branch**: `feature/phase-3-gps-processing`  
**Commit Baseline**: `92aed2c` (Phase 2 GPX and Route Pipeline Correctness)

---

## 1. Current State of Location & Metrics

| Responsibility | Current Owner | Observations / Weaknesses |
|:---|:---|:---|
| **Location Ingestion** | `LocationService` | Bridges `CLLocationManager` to Swift concurrency, converts to `LocationSample`. |
| **Location Forwarding** | `RideDataCoordinator` | Fans raw `LocationSample` directly to `MetricsEngine`, `NavigationEngine`, and `RideEngine`. |
| **GPS Acceptance** | Direct acceptance | No validation of timestamp age, timestamp monotonic ordering, or coordinate plausibility. |
| **Distance Calculation** | `WorkoutService` / `Location` | Uses workout-reported distance or naive point-to-point addition without drift or teleport filters. |
| **Speed Derivation** | Platform reported | Directly consumes `location.speedMetersPerSecond` without validation or fallback to implied speed. |
| **Stationary Drift** | Unmitigated | GPS coordinate flutter while standing still accumulates as artificial distance. |
| **Pause & Resume** | Platform dependent | No explicit gap isolation or recovery anchor resetting. |
| **GPS Outages** | Unhandled | Long signal loss followed by recovery risks bridge jumps. |

---

## 2. Target Architecture (Phase 3)

```
CoreLocationManager
       ↓
LocationService (Platform owner: normalizes raw CLLocation)
       ↓
LocationSample (Structurally valid domain value type)
       ↓
GPSProcessor (Deterministic processing engine & actor)
       ├── 1. Sequence increment & lifecycle check
       ├── 2. Timestamp ordering & age validation (GPSTimestampValidator)
       ├── 3. Horizontal accuracy & quality classification (GPSAccuracyValidator)
       ├── 4. Pause / outage recovery anchor handling
       ├── 5. Geographic distance calculation (CoordinateDistanceCalculating)
       ├── 6. Implied speed & plausibility check (GPSPlausibilityValidator)
       ├── 7. Accuracy-overlap drift filtering
       ├── 8. Speed selection (reported vs derived) (GPSSpeedEstimator)
       ├── 9. Speed smoothing (TimeWeightedSpeedSmoother)
       ├── 10. Movement classification with hysteresis (MovementClassifier)
       └── 11. Distance accumulation & anchor advancement (GPSDistanceAccumulator)
              ↓
       GPSProcessingResult (.accepted, .rejected, .ignored)
              ↓
       RideDataCoordinator
       ├── .accepted → MetricsEngine (speed + total distance)
       ├── .accepted → NavigationEngine (route matching)
       └── .rejected / .ignored → Observability & diagnostics
```
