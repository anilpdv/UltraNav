# Bluetooth Architecture & Protocol Specification

## 1. Overview
The UltraNav Bluetooth Subsystem provides robust, zero-copy, memory-safe BLE connectivity and telemetry decoding for cycling sensors on watchOS. It operates purely on asynchronous streams, actors, and decoupled pure parsing pipelines.

```
       +-------------------------------------------------------------+
       |                   CoreBluetooth Hardware                    |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |               CBCentralManager / CBPeripheral               |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |                  BluetoothService (Actor)                   |
       |  - Connection Lifecycle & Supervision                       |
       |  - Reconnect Exponential Backoff (SensorReconnectPolicy)    |
       +-------------------------------------------------------------+
                                      |
                                      v (SensorMeasurementPacket)
       +-------------------------------------------------------------+
       |               CyclingSensorPacketParser (Actor)             |
       |  - Multi-sensor Stateful Routing via SensorPacketProcessor  |
       +-------------------------------------------------------------+
              |                       |                       |
              v                       v                       v
       +---------------+      +---------------+      +---------------+
       | HeartRate     |      | CyclingPower  |      | CSC           |
       | Parser        |      | Parser        |      | Parser        |
       +---------------+      +---------------+      +---------------+
              |                       |                       |
              +-----------------------+-----------------------+
                                      |
                                      v
                        [SensorMeasurementSample]
```

---

## 2. Supported Standard Profiles & Services

| Service | UUID | Characteristic | Characteristic UUID | Measurement Type |
|---|---|---|---|---|
| Heart Rate | `0x180D` | Heart Rate Measurement | `0x2A37` | Heart Rate (BPM, RR Intervals, Sensor Contact) |
| Cycling Power | `0x1818` | Cycling Power Measurement | `0x2A63` | Instantaneous Power (Watts), Cadence (Crank Revs) |
| Cycling Speed and Cadence | `0x1816` | CSC Measurement | `0x2A5B` | Wheel Speed (km/h) & Cadence (RPM) |

---

## 3. Disconnection & Reconnection Strategy

### Disconnection Classification
`SensorReconnectPolicy` categorizes disconnect events into two primary categories:
1. **Link Loss / Unexpected**: Peripheral disconnected without user intent, connection timeout, signal loss. Automatically triggers exponential backoff reconnect up to a maximum attempt limit (default 10).
2. **Manual Disconnect**: Explicit user or application action (`disconnect()`). Does not trigger automatic reconnect attempts unless overridden.

### Exponential Backoff Schedule
$$ \text{Delay}(attempt) = \min(\text{initialDelay} \times \text{multiplier}^{\text{attempt} - 1}, \text{maxDelay}) $$
- **Initial Delay**: 1.0s
- **Multiplier**: 2.0x
- **Max Delay**: 30.0s
- **Max Attempts**: 10
- **Attempt Reset**: Reconnection attempt counter resets immediately upon receiving a successful `.connected` event.

---

## 4. Multi-Sensor Concurrency & Isolation
- Parsers maintain distinct, isolated rolling revolution and timestamp state per `SensorIdentifier`.
- A bike equipped with both a power meter (reporting crank cadence) and a dedicated wheel speed sensor (reporting wheel revs) is handled correctly without cross-sensor state contamination.
- State is encapsulated in value-type revolution tracking models (`CyclingPowerRevolutionState`, `CSCRevolutionState`) inside `SensorPacketProcessor`.
