# UltraNav Metric Source Policy (Phase 9)

## 1. Metric Source Priorities

Source arbitration defines the authoritative data source when multiple sensors report the same metric kind.

| Metric Kind | Priority 1 (Preferred) | Priority 2 (Fallback) | Priority 3 (Tertiary) |
|---|---|---|---|
| **Speed** | Bluetooth Wheel Sensor | GPS Processed Speed | HealthKit Speed |
| **Distance** | Bluetooth Wheel Odometer | GPS Cumulative Distance | HealthKit Distance |
| **Heart Rate** | Bluetooth Heart Rate Strap | Apple Watch HealthKit HR | — |
| **Cadence** | Bluetooth Power Meter Cadence | Bluetooth Speed/Cadence Sensor | — |
| **Power** | Bluetooth Cycling Power Meter | — | — |
| **Active Energy**| HealthKit Active Energy | — | — |
| **Altitude** | GPS / CoreLocation Altitude | Barometer (if available) | — |

## 2. Hysteresis & Switch-Back Delay

- When a preferred primary source (e.g. BLE HR chest strap) becomes `.unavailable` or `.stale`, the engine falls back **immediately** to the secondary source (Apple Watch optical HR).
- When the preferred source recovers, the arbitrator observes the recovered signal for a configured `switchBackDelaySeconds` (default: **3.0s**) before switching back to prevent flapping in fringe RF conditions.

## 3. Cumulative Distance & Energy Continuity

- Switching sources (e.g., GPS to Wheel Sensor) does not reset or jump the ride's cumulative distance.
- `CumulativeMetricTracker` calculates a source offset:
  $$\text{Offset} = \text{Current Displayed Total} - \text{New Source Raw Value}$$
- When a sensor power-cycles and resets its raw hardware odometer to zero, the tracker detects the negative step ($>10\text{m}$ drop) and re-anchors the offset to maintain continuous monotonic advancement.
