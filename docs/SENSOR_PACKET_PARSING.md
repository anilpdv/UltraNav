# Sensor Packet Parsing & Rollover Protocol

## 1. Safe Cursor Navigation (`SensorPacketCursor`)

All Bluetooth SIG characteristic payloads are parsed using the bounds-checked reader `SensorPacketCursor`.

### Invariants & Safety Guarantees
- Zero out-of-bounds index access: Reading beyond payload length throws `SensorPacketParsingFailure.unexpectedPacketLength`.
- Zero force-unwrapping.
- Strict Little-Endian decoding for standard Bluetooth SIG multi-byte integers:
  - `UInt8` (1 byte)
  - `UInt16LE` (2 bytes)
  - `Int16LE` (2 bytes, two's complement for signed power / torque)
  - `UInt24LE` (3 bytes)
  - `UInt32LE` (4 bytes)

---

## 2. Sensor Protocols & Bitfield Layouts

### 2.1 Heart Rate (`0x2A37`)
- **Flags (Byte 0)**:
  - Bit 0 (`0x01`): Value Format (`0` = 8-bit BPM, `1` = 16-bit BPM).
  - Bit 1 & 2 (`0x06`): Sensor Contact Status (`0x04` = contact detected, `0x06` = contact supported and detected).
  - Bit 3 (`0x08`): Energy Expended Present (`UInt16` in kJ).
  - Bit 4 (`0x10`): RR-Interval Present (`UInt16` values in 1/1024s resolution).

### 2.2 Cycling Power (`0x2A63`)
- **Flags (Bytes 0-1, UInt16LE)**:
  - Bit 0: Pedal Power Balance Present.
  - Bit 2: Accumulated Torque Present.
  - Bit 5: Crank Revolution Data Present (Cumulative Crank Revolutions `UInt16LE`, Last Crank Event Time `UInt16LE` in 1/1024s).
  - Bit 11: Extreme Angles Present.
- **Instantaneous Power (Bytes 2-3)**: `Int16LE` (Watts).
- **Cadence Derivation**:
  $$ \Delta\text{Revs} = (\text{CurrentRevs} - \text{PreviousRevs}) \pmod{65536} $$
  $$ \Delta\text{Time} = \frac{(\text{CurrentTime} - \text{PreviousTime}) \pmod{65536}}{1024.0} $$
  $$ \text{Cadence (RPM)} = \left(\frac{\Delta\text{Revs}}{\Delta\text{Time}}\right) \times 60.0 $$

### 2.3 Cycling Speed and Cadence (`0x2A5B`)
- **Flags (Byte 0)**:
  - Bit 0 (`0x01`): Wheel Revolution Data Present (Cumulative Wheel Revolutions `UInt32LE`, Last Wheel Event Time `UInt16LE` in 1/1024s).
  - Bit 1 (`0x02`): Crank Revolution Data Present (Cumulative Crank Revolutions `UInt16LE`, Last Crank Event Time `UInt16LE` in 1/1024s).
- **Speed Derivation**:
  $$ \Delta\text{WheelRevs} = (\text{CurrentWheelRevs} - \text{PreviousWheelRevs}) \pmod{2^{32}} $$
  $$ \Delta\text{WheelTime} = \frac{(\text{CurrentWheelTime} - \text{PreviousWheelTime}) \pmod{65536}}{1024.0} $$
  $$ \text{Speed (m/s)} = \frac{\Delta\text{WheelRevs} \times \text{WheelCircumferenceMeters}}{\Delta\text{WheelTime}} $$

---

## 3. Rollover Math & Boundary Protection
1. **16-bit Timer Rollover (1/1024s)**:
   - Rolls over every $65536 / 1024 \approx 64$ seconds.
   - Handled cleanly via `(current &+ 65536 - previous) % 65536`.
2. **16-bit Crank Revolution Rollover**:
   - Handled cleanly via modulo 65536 arithmetic.
3. **32-bit Wheel Revolution Rollover**:
   - Handled cleanly via unsigned integer overflow wrapping (`&+`).
4. **Stale / Zero-Delta Prevention**:
   - If $\Delta\text{Time} \le 0$ or $\Delta\text{Revs} == 0$, cadences/speeds are reported as 0 or skipped if time elapsed exceeds stall threshold.
