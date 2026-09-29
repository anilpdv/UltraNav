# Phase 8 Baseline: Bluetooth Sensor Reliability & Protocol Correctness

## 1. Current State Assessment
- **Central Manager Owner**: `BluetoothService` wrapping `CBCentralManaging`.
- **Supported Sensor Types**: Heart Rate (0x180D), Cycling Power (0x1818), Cycling Speed & Cadence (0x1816).
- **Existing Parsing Layer**: `CyclingSensorPacketParser` with legacy adapter wrappers (`LegacyHeartRateParserAdapter`, `LegacyCyclingPowerParserAdapter`, `LegacyCSCParserAdapter`).
- **Connection Pipeline**: Basic connection states exist; need strict protocol-compliant characteristic discovery, notification enablement verification, counter rollover logic, and bounded reconnect policy.
- **Baseline Commit**: `56e9636` (Phase 7 merged).

---

## 2. Phase 8 Scope & Goals
1. Safe, bounds-checked binary parsing via `SensorPacketCursor`.
2. Dedicated spec-compliant parsers (`HeartRateMeasurementParser`, `CyclingPowerMeasurementParser`, `CSCMeasurementParser`).
3. Precise 16-bit and 32-bit cumulative revolution and event-time rollover handling with wrap compensation.
4. Clean multi-sensor packet processing and deterministic reconnect policy.
5. Removal of all `Legacy*ParserAdapter` files and enforcement via guard scripts.
