# Phase 9 Implementation Map: Cycling Metrics and Source Arbitration

## 1. Domain Models & Observations (`UltraNav/Metrics/Observations/`)
- `MetricKind.swift`: Primary (`speed`, `cumulativeDistance`, `heartRate`, `cadence`, `power`, `activeEnergy`, `altitude`, `elapsedTime`, `activeTime`, `movingTime`).
- `DerivedMetricKind.swift`: Derived (`averageSpeed`, `maximumSpeed`, `averageHeartRate`, `maximumHeartRate`, `averageCadence`, `maximumCadence`, `averagePower`, `maximumPower`, `normalizedPower`, `intensityFactor`, `trainingStressScore`).
- `MetricSource.swift`: Explicit source enum (`.gps`, `.healthKit`, `.bluetooth(sensor: SensorIdentifier)`, `.manual`, `.derived`).
- `MetricValue.swift`: Canonical typed SI/domain values (`speedMetersPerSecond`, `cumulativeDistanceMeters`, `heartRateBeatsPerMinute`, `cadenceRevolutionsPerMinute`, `powerWatts`, `cumulativeActiveEnergyKilocalories`, `altitudeMeters`).
- `MetricQuality.swift`: Observation quality (`valid`, `derived`, `estimated`, `uncertain`).
- `MetricAvailability.swift`: Availability status (`available`, `stale`, `unavailable`, `invalid`).
- `MetricSemantics.swift`: (`instantaneous`, `cumulative`, `derived`).
- `MetricObservation.swift`: Complete measurement payload with `measuredAt`, `receivedAt`, `sequence`, `quality`.
- `SelectedMetricState.swift`: Unified presentation model.

## 2. Validation (`UltraNav/Metrics/Validation/`)
- `MetricValidationPolicy.swift`: Structural boundaries (speed max 40m/s, HR max 250, Cadence max 250, Power -500 to 3000W, Altitude -500 to 10000m).
- `MetricValidating.swift` & `StandardMetricValidator.swift`: Validation logic rejecting non-finite, out-of-bounds, out-of-order timestamps, or non-monotonic cumulative metrics.

## 3. Freshness (`UltraNav/Metrics/Freshness/`)
- `MetricFreshness.swift`: Metric-specific timeout durations (speed 5s, HR 10s, cadence 5s, power 3s, altitude 10s, distance 15s, energy 30s).
- `MetricFreshnessEvaluating.swift` & `MetricFreshnessEvaluator.swift`: Computes availability based on observation age against evaluation date.

## 4. Source Arbitration (`UltraNav/Metrics/Arbitration/`)
- `MetricSourcePolicy.swift` & `MetricSourcePreference.swift`: Configurable priorities per metric kind (`outdoorCycling`).
- `MetricArbitrator.swift`: Evaluates candidate streams, tracks switch-back hysteresis delay (`switchBackDelaySeconds: 3`), tie-breaks equal rank candidates, and handles fallback.
- `MetricSelection.swift` & `MetricSourceTransition.swift`: Explicit transition tracking.

## 5. Aggregation & Cumulative Tracking (`UltraNav/Metrics/Aggregation/`)
- `CumulativeMetricTracker.swift`: Non-decreasing distance & energy tracking with source activation offsets and reset re-anchoring.
- `TimeWeightedAverage.swift`: Integration engine weighting previous sample value across time deltas up to freshness caps.
- `MaximumAccumulator.swift`: Tracks validated peaks.
- `MovingMetricAccumulator.swift`: Moving vs. active vs. elapsed time integration.

## 6. Power Engine (`UltraNav/Metrics/Power/`)
- `PowerSmoothingConfiguration.swift` & `PowerSmoother.swift`: 3s, 10s, 30s rolling averages with max sample gap behavior.
- `FunctionalThresholdPower.swift`: Validated strictly positive FTP.
- `NormalizedPowerCalculator.swift`: 30s rolling 4th-power mean algorithm with strict 1Hz resampling buckets.
- `IntensityFactorCalculator.swift`: $NP / FTP$.
- `TrainingStressScoreCalculator.swift`: $\frac{t \times NP \times IF}{FTP \times 3600} \times 100$.
- `PowerMetricsSnapshot.swift`: Complete power telemetry snapshot.

## 7. Lap Engine (`UltraNav/Metrics/Laps/`)
- `LapTrigger.swift` (`.manual`, `.distance`, `.time`, `.routePoint`).
- `LapConfiguration.swift` & `AutomaticLapPolicy.swift`.
- `LapRecord.swift` & `LapMetricsSummary.swift`: Immutable lap checkpoints.
- `LapEngine.swift`: Manages active lap accumulation and boundary finalization.

## 8. Ride Summary (`UltraNav/Metrics/Summary/`)
- `RideMetricsSummary.swift`: Frozen end-of-ride summary with data quality coverage ratios.
- `RideSummaryBuilder.swift`: Compiles final metrics on finish.

## 9. Engine Integration (`UltraNav/Engines/Metrics/` & `UltraNav/Domain/Metrics/`)
- `MetricsEngine.swift`: Upgraded to coordinate all above components, react to `TickProviding`, consume mapped inputs, and publish deterministic `MetricsSnapshot`.
- `MetricsViewStateMapper.swift`: Translates domain snapshot to presentation state.
