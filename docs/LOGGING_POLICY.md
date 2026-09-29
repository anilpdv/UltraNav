# UltraNav Logging Policy

## 1. Prohibited Logging Practices
- **No `print()`, `debugPrint()`, or `dump()`** in production code.
- **No per-sample logging**: High-frequency streaming events (e.g. GPS locations, BLE sensor measurements, heart rate packets) must update counters or gauges, never emit log lines.
- **No raw snapshot or complex object dump**: Do not log raw `RideSnapshot` or GPX data.

## 2. Privacy Classifications

| Tier | Examples | Handling |
|---|---|---|
| `public` | State changes, operational status, errors without PII | Logged directly to system console and exports |
| `privateData` | Non-sensitive internal identifiers, sensor types | Formatted safely in diagnostics, salt-hashed for export |
| `sensitive` | Exact coordinates, HR values, power watts, user waypoint names, file paths | Redacted as `<redacted>` in standard system logs and excluded from diagnostic exports |

## 3. Log Levels
- `trace`: Deep developer-only control flow.
- `debug`: Detailed diagnostics useful during development/staging.
- `information`: Normal lifecycle state transitions (e.g. ride prepared, workout started).
- `notice`: Significant expected occurrences (e.g. route completed, sensor connection requested).
- `warning`: Recoverable degradations or warnings (e.g. sensor disconnected, off-route).
- `error`: Failed operation (e.g. route parse failed, save failed).
- `critical`: Integrity or session survival at risk (e.g. workout session terminated unexpectedly).
