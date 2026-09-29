# Phase 1J: Metrics Engine Architecture

## Overview
Phase 1J establishes the boundary for live measurement ingestion, origin source provenance, temporal freshness tracking, and basic metric aggregation in UltraNav.

```
┌─────────────────────────────────────────────────────────────┐
│                    Measurement Sources                      │
├─────────────────────┬───────────────────┬───────────────────┤
│   LocationService   │  HealthKitService │  BluetoothService │
│ (Speed, Altitude)   │ (HR, Dist, Energy)│(HR, Power, Cadence│
└──────────┬──────────┴─────────┬─────────┴─────────┬─────────┘
           │                    │                   │
           └────────────────────┼───────────────────┘
                                ▼
                   ┌─────────────────────────┐
                   │      MetricsEngine      │
                   ├─────────────────────────┤
                   │ • MetricObservation     │
                   │ • MetricFreshness       │
                   │ • MetricStore (Buffers) │
                   │ • StandardValidator     │
                   │ • SourceSelection       │
                   │ • SummaryBuilder        │
                   └────────────┬────────────┘
                                │
                                ▼
                      ┌───────────────────┐
                      │  MetricsSnapshot  │
                      └─────────┬─────────┘
                                │
                 ┌──────────────┴──────────────┐
                 ▼                             ▼
            RideEngine               Presentation Adapters
     (Ride State Coordination)       (LegacyMetricsAdapter)
```

## Architectural Components

1. **Domain Models (`Domain/Metrics/`)**:
   - `MetricSource`: Discriminated origin identifier (`.coreLocation`, `.healthKit`, `.bluetooth(sensorID:)`, `.derived`).
   - `MetricValue`: Strongly typed measurement values (`.speed`, `.heartRate`, `.cadence`, `.power`, `.distance`, `.altitude`, `.energy`).
   - `MetricObservation`: Point-in-time timestamped reading tagged with origin source and value.
   - `MetricFreshness`: Lifecycle freshness state (`.fresh`, `.stale`, `.expired`) computed dynamically against engine clock.
   - `CurrentMetric<T>`: Wrapper encapsulating live value, source, timestamp, and freshness.
   - `MetricsSnapshot`: Pure immutable state capture containing current readings, rolling summaries (avg, max), availability flags, and timestamp.
   - `MetricsEngineState`: Explicit engine lifecycle (`.idle`, `.active`, `.paused`, `.stopped`).

2. **Aggregation & Validation (`Metrics/`)**:
   - `AverageCalculating` & `MaximumCalculating`: Rolling numerical statistics over sliding observation buffers.
   - `TimeWeightedAverage`: Duration-weighted average calculations.
   - `LegacyPowerSmoothing`: 3-second and windowed power smoothing.
   - `StandardMetricValidator`: Physical bounds sanity checking (e.g. non-negative speed/cadence, realistic HR 30-260 bpm).
   - `TemporaryLatestSourceSelector`: Phase 1 protocol-driven source selector preserving latest-event semantics in preparation for Phase 9 priority hierarchies.

3. **Coordination & Presentation (`Engines/Metrics/`, `Presentation/Metrics/`)**:
   - `MetricsEngine`: Coordinates ingestion streams, updates memory-bounded `RollingSampleBuffer` instances, applies validation, and emits `MetricsSnapshot` streams.
   - `LegacyMetricsAdapter`: Projection adapter for legacy views expecting `RideMetrics`.
   - `RideEngine.consume(metrics:)`: Pure consumer integration.
