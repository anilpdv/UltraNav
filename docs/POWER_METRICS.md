# UltraNav Advanced Power Metrics (Phase 9)

## 1. Rolling Power Smoothing

`PowerSmoother` maintains a timestamped sample buffer up to 35 seconds to compute:
- **3-second Power** ($P_{3s}$)
- **10-second Power** ($P_{10s}$)
- **30-second Power** ($P_{30s}$)

Sample gaps $>3.0\text{s}$ mark the smoothed power value as stale rather than interpolating artificial zeros unless zero power is explicitly transmitted by the crank/pedal sensor.

## 2. Normalized Power (NP)

Normalized Power models the physiological cost of variable intensity cycling using Dr. Andrew Coggan's algorithm:
1. Calculate a continuous 30-second moving average of power: $P_{30s}(t)$.
2. Raise each 30-second moving average to the 4th power: $(P_{30s}(t))^4$.
3. Compute the mean of all 4th-power values across eligible ride moving time.
4. Take the 4th root:
   $$\text{NP} = \left(\frac{1}{N} \sum_{i=1}^N P_{30s}(i)^4\right)^{1/4}$$

Eligibility: Calculated once the ride duration reaches $\ge 30\text{ seconds}$.

## 3. Intensity Factor (IF)

Intensity Factor expresses ride intensity relative to Functional Threshold Power (FTP):
$$\text{IF} = \frac{\text{NP}}{\text{FTP}}$$

If no FTP is configured in `MetricsConfiguration`, IF remains `nil`.

## 4. Training Stress Score (TSS)

Training Stress Score measures the total training load:
$$\text{TSS} = \frac{t \times \text{NP} \times \text{IF}}{\text{FTP} \times 3600} \times 100$$
where $t$ is the active ride duration in seconds.
