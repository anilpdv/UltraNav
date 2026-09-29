# UltraNav Diagnostic Privacy

## Privacy Guarantee
UltraNav is designed for cycling in the real world. Diagnostics and logging must **never** record or leak personally identifying or sensitive user fitness/geographic information.

## Specifically Excluded from Diagnostic Logs & Exports:
1. **Precise Location**: No latitude, longitude, altitude coordinates, or street address metadata.
2. **Route Geometry & Personal Route Names**: No waypoint names or track coordinate arrays.
3. **Biometrics & Physical Health**: No instantaneous heart rate, power watts, cadence, or calorie counters.
4. **Persistent Hardware IDs**: Peripheral Bluetooth UUIDs are not exposed directly in exports.
5. **Raw File Paths**: Local device file system paths are omitted.

## Permitted in Diagnostic Logs & Exports:
- Subsystem health status (`healthy`, `degraded`, `unavailable`, `failed`)
- Normalized `FailureID` classifications and occurrence counts
- Operation durations measured via `MonotonicClock`
- High-level aggregate metrics: total sample counts, packet counts, drop counts
- App lifecycle state and schema version numbers
