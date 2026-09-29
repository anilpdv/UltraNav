# Phase 8 Implementation Map

## 1. Subsystem Structure
- `UltraNav/Services/Sensors/Parsing/`:
  - `SensorPacketCursor.swift`: Bounds-checked reader for UInt8, UInt16, UInt32, Int16, and optional fields.
  - `HeartRateFlags.swift`, `HeartRateMeasurement.swift`, `HeartRateMeasurementParser.swift`
  - `CyclingPowerFlags.swift`, `CyclingPowerMeasurement.swift`, `CyclingPowerMeasurementParser.swift`, `CyclingPowerRevolutionState.swift`
  - `CSCFlags.swift`, `CSCMeasurement.swift`, `CSCMeasurementParser.swift`, `CSCRevolutionState.swift`
  - `SensorPacketProcessor.swift`: Dispatches incoming raw byte packets to appropriate typed parsers.
  - `SensorReconnectPolicy.swift`: Governs bounded reconnection attempts without overlapping retries.
- Delete:
  - `LegacyHeartRateParserAdapter.swift`
  - `LegacyCyclingPowerParserAdapter.swift`
  - `LegacyCSCParserAdapter.swift`
- Guard Scripts:
  - Add legacy parser adapters to `check_legacy_symbols.sh` and `check_dead_files.sh`.
