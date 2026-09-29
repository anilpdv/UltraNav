# Metrics Legacy Limitations & Phase 9 Migration Plan

## Current Legacy Limitations Preserved in Phase 1J
1. **Latest-Event-Wins Selection**: Current source selection employs `TemporaryLatestSourceSelector`, where the newest incoming packet across Bluetooth, HealthKit, or Core Location wins. This preserves behavioral stability during Phase 1 refactoring without breaking UI assumptions.
2. **Simplified Rolling Summaries**: Aggregations currently compute rolling arithmetic means and peak values over in-memory circular buffers rather than weighted integration across pauses.
3. **No Dynamic Outlier Smoothing**: GPS speed glitches and spike rejection are deferred to Phase 4 (Location Filtering) and Phase 9 (Advanced Metrics Engine).

## Phase 9 Enhancements
- Priority-ranked arbitration hierarchy (e.g. `BLE Power/Speed > HealthKit Workout > GPS Speed`).
- Exponential Moving Average (EMA) and Normalized Power (NP) 30s rolling algorithm.
- Auto-pause movement detectors with configurable speed thresholds.
- Lap segmentation and interval analytics engine.
