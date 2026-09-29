# GPS Processing Policy

UltraNav processes all incoming device location samples through a deterministic, isolated `GPSProcessor` actor pipeline prior to metric accumulation or route matching.

## 1. Pipeline Stages

1. **Processor Lifecycle Mode**:
   - `idle`: Samples ignored (`.notRecording`).
   - `finished`: Samples ignored (`.finished`).
   - `paused`: Samples rejected with zero distance accumulation (`.processorPaused`).
   - `recording`, `recoveringFromPause`, `recoveringFromOutage`: Active evaluation.

2. **Structural Validation**:
   - Longitude $\in [-180, 180]$, Latitude $\in [-90, 90]$.
   - Finite floating-point values only.

3. **Horizontal Accuracy Validation**:
   - Accuracy $> 0$ and finite.
   - Thresholds:
     - $\le 5.0\text{ m}$: `GPSQuality.excellent`
     - $\le 10.0\text{ m}$: `GPSQuality.good`
     - $\le 25.0\text{ m}$: `GPSQuality.usable`
     - $> 25.0\text{ m}$: Rejected (`.accuracyTooPoor`).

4. **Timestamp & Monotonicity Validation**:
   - Sample age must not exceed maximum age threshold (default 10s).
   - Monotonically increasing timestamps ($t_{\text{current}} > t_{\text{prev}}$). Out-of-order and duplicate timestamps are rejected.

5. **Geographic Plausibility & Jump Rejection**:
   - Great-circle distance between successive points must not exceed maximum plausible jump distance (default 300m for 1s sample, or implied speed $> 45\text{ m/s}$).
   - Accuracy overlap checking: If distance between positions is within the sum of their horizontal accuracy radii, drift is flagged.

6. **Speed Selection & Window Smoothing**:
   - Primary: Device/platform-reported speed if accuracy is valid and speed $\ge 0$.
   - Fallback: Distance / Time delta derived speed.
   - Smoothing: Time-weighted sliding window smoothing over a configurable window (default 3.0s).

7. **Movement Classification & Hysteresis**:
   - Asymmetric state transition:
     - Moving confirmation: Requires $N_{\text{moving}} \ge 2$ consecutive moving samples (speed $\ge 1.2\text{ m/s}$ and position delta $\ge 2.0\text{ m}$).
     - Stationary confirmation: Requires $N_{\text{stationary}} \ge 3$ consecutive stationary samples (speed $\le 0.5\text{ m/s}$ with accuracy overlap).
   - Prevents micro-jitter while stopped at traffic lights.

8. **Distance Accumulation & Gap Handling**:
   - Gated on `MovementState.moving`. Stationary jitter adds exactly $0.0\text{ m}$.
   - Pause recovery: First post-pause sample establishes a new anchor with $0.0\text{ m}$ increment (prevents teleport bridge).
   - Outage recovery: First post-outage sample establishes a new anchor with $0.0\text{ m}$ increment (prevents false straight-line interpolation across tunnels).
   - Long gap: If time delta exceeds 15s without an explicit pause event, bridging is suppressed.
