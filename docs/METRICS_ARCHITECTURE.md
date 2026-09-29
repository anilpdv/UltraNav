# UltraNav Metrics Architecture (Phase 9)

## 1. Overview & Single Ownership

`MetricsEngine` is the single owner and source of truth for all cycling metrics in UltraNav. Metric calculations, accumulation, and source arbitration are centralized in `UltraNav/Metrics/` and `UltraNav/Engines/Metrics/`.

```
GPSProcessor / LocationService
    ├── Speed (m/s)
    ├── Distance (m)
    └── Altitude (m)
HealthKitService
    ├── Heart Rate (bpm)
    ├── Active Energy (kcal)
    └── Distance (m)
BluetoothSensorService
    ├── Heart Rate (bpm)
    ├── Instantaneous Power (W)
    ├── Cadence (rpm)
    └── Wheel Speed & Distance
          ↓
     MetricsEngine
          ├── 1. Metric Observation Validation (Range, Plausibility, Time)
          ├── 2. Candidate Observation Storage
          ├── 3. Metric Source Arbitration (Priority, Availability, Hysteresis)
          ├── 4. Cumulative Tracking (Offset Re-anchoring)
          ├── 5. Time-Weighted Moving Accumulation & Power Smoothing
          ├── 6. Lap Engine (Manual & Distance Auto-Laps, Immutable Summaries)
          ├── 7. Advanced Power Metrics (NP, IF, TSS)
          └── 8. Ride Summary Builder
          ↓
     MetricsSnapshot (Published asynchronously via AsyncStream)
```

## 2. Core Subsystems

### Observation Pipeline
- `MetricObservation`: Timestamped record with canonical `MetricKind`, `MetricValue`, `MetricSource`, `measuredAt`, and `receivedAt`.
- `MetricValidator`: Validates values against physical cycling limits (`MetricValidationPolicy`). Rejects non-finite, out-of-range, and corrupt frames.

### Freshness & Availability
- `MetricFreshnessEvaluator`: Evaluates age of observations against kind-specific timeouts (`MetricFreshness`).
- `MetricAvailability`: Four distinct states — `.available`, `.stale`, `.unavailable`, `.invalid`. Zero is preserved as a valid numeric reading and never confused with `.unavailable`.

### Source Arbitration
- `MetricArbitrator`: Performs priority-ranked arbitration per metric kind based on `MetricSourcePolicy`.
- Incorporates a 3.0-second switch-back delay hysteresis to prevent flapping between fallback and preferred sensors.

### Aggregation & Power
- `CumulativeMetricTracker`: Maintains continuous, monotonically non-decreasing distance and energy totals across sensor disconnects, reconnects, and source handoffs.
- `TimeWeightedAverage` & `MaximumAccumulator`: Computes duration-weighted averages and peak values.
- `PowerSmoother`: Computes 3s, 10s, and 30s rolling power averages.
- `NormalizedPowerAccumulator`: Computes 4th-power rolling windows for Normalized Power (NP), Intensity Factor (IF), and Training Stress Score (TSS).

### Lap Subsystem
- `LapEngine`: Handles manual lap triggers and automatic distance-based laps, generating immutable `LapRecord` instances with frozen metrics snapshots.
