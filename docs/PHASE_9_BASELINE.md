# Phase 9 Baseline Report

## Baseline Commit
- **Commit**: `268f496` (merged Phase 8 into main)
- **Branch**: `feature/phase-9-cycling-metrics`
- **Target Platform**: `platform=watchOS Simulator,id=DDF0DEC5-1398-49B0-93E2-AABAB423884D`

---

## Current Architecture Audit

### 1. Metric Ownership
- `UltraNav/Engines/Metrics/MetricsEngine.swift`: Rudimentary state machine storing raw arrays in `MetricStore`.
- Lacks source arbitration with hysteresis, cumulative offset tracking, discrete 1Hz power resampling, robust Normalized Power calculation, and immutable lap management.

### 2. Metric Observation & Value Models
- `UltraNav/Domain/Metrics/MetricObservation.swift`: Holds simple `.speed`, `.distance`, `.heartRate`, `.power`, `.cadence`, `.energy`, `.altitude`.
- Lacks explicit distinction between measured vs. received timestamps, metric kinds, typed canonical `MetricValue` enum cases, and discrete `MetricQuality`.

### 3. Source Selection & Freshness
- `UltraNav/Metrics/Selection/MetricSourceSelecting.swift` uses `TemporaryLatestSourceSelector` which just picks the latest timestamp regardless of source priority, link flapping, or cumulative offsets.
- Lacks `MetricFreshnessEvaluator`, `MetricSourcePolicy` priority tables, and `switchBackDelaySeconds` recovery hysteresis.

### 4. Cumulative Value & Distance Contamination
- GPS and HealthKit cumulative distances are stored as raw observations without source-rebasing or activation offsets (`CumulativeMetricTracker`).
- Wheel distance packets can cause distance jumping or regression when toggling between GPS and BLE wheel sensors.

### 5. Power Smoothing & Advanced Cycling Workload
- `LegacyPowerSmoothing.swift`: Primitive time-window filter that does not handle sample gaps, zero power coasting, or 1Hz discrete time alignment.
- Lacks Normalized Power (NP) 4th-power mean algorithm, Intensity Factor (IF), and Training Stress Score (TSS) calculators.

### 6. Lap Engine
- Missing formal `LapRecord`, `LapEngine`, `LapMetricsSummary`, and `LapTrigger` lifecycle handling.

---

## Test Suite Baseline
- 98 Swift Testing unit tests in 57 suites passing (100%).
- 3 UI journey integration tests passing.
- 0 failures.
