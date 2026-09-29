# Climb Subsystem Legacy Limitations

This document tracks known limitations of the legacy climb detection and elevation calculation algorithms preserved during the Phase 1K boundary extraction, to be addressed in Phase 10.

## Preserved Legacy Quirks (Targeted for Phase 10)

1. **Elevation Profile Resampling & Noise**:
   - Legacy detection works directly on discrete GPX track points rather than distance-resampled interpolated points. Noisy GPS elevation spikes can artificially create false short steep climbs or distort grade percentage.

2. **Threshold Sensitivity**:
   - The legacy `grade >= 3.0%` threshold and hardcoded score criteria (`score >= 1200` and `distance >= 400m`) can split a single long mountain climb with brief false flats into multiple fragmented climbs.

3. **Grade Smoothing**:
   - Live grade percentage uses a simple fixed exponential moving average `(0.7 * prev + 0.3 * raw)` over a 15-second buffer. Phase 10 will introduce Kalman or windowed regression smoothing for cleaner gradient display.

4. **Descent & False Flat Handling**:
   - Incomplete descent filtering in multi-tier mountain passes. Phase 10 will introduce standard cycling industry ClimbPro segmentation (e.g. allowing up to 150m of flat/minor descent within a sustained major climb).
