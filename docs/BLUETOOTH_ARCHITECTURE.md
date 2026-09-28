# Bluetooth Service Architecture

## Overview
UltraNav isolates all Bluetooth Low Energy (BLE) peripheral discovery, connection lifecycles, GATT service/characteristic exploration, notification subscription, and raw measurement packet parsing behind the pure `SensorProviding` interface.

No view, view model, domain model, or engine interacts directly with CoreBluetooth types (`CBCentralManager`, `CBPeripheral`, `CBService`, `CBCharacteristic`, `CBUUID`).

## Boundary Architecture

```
CoreBluetooth
      │
      ├── CBCentralManager
      ├── CBPeripheral
      ├── CBService
      └── CBCharacteristic
              │
              ▼
   CoreBluetoothDelegateBridge & PeripheralDelegateBridge
              │
              ▼
       BluetoothService (@MainActor)
              │
              ├── BluetoothAvailability
              ├── SensorScanRequest
              ├── PeripheralContext
              ├── SensorDiscovery
              └── SensorConnectionState
                       │
                       ▼
            SensorMeasurementPacket
                       │
                       ▼
             SensorPacketParsing
       (Legacy adapters -> Domain Samples)
                       │
                       ▼
              SensorServiceEvent
                       │
                       ▼
               SensorProviding
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
       Future RideEngine   Future MetricsEngine
```

## Supported Sensor Profiles
- **Heart Rate Service (`180D`)**: Measurement (`2A37`)
- **Cycling Speed & Cadence (`1816`)**: Measurement (`2A5B`), Feature (`2A5C`), Location (`2A5D`)
- **Cycling Power Service (`1818`)**: Measurement (`2A63`), Feature (`2A65`), Location (`2A5D`)
- **Battery Service (`180F`)**: Battery Level (`2A19`)

## Connection Lifecycle
```
disconnected -> connecting -> connected -> discoveringServices -> discoveringCharacteristics -> subscribing -> ready
```
- Disconnections are classified as either explicit/user-requested or unexpected.
- Unexpected disconnections emit `.failed(.disconnectedUnexpectedly(sensorID))` and preserve the `PeripheralContext` for policy-driven reconnection in Phase 8.

## Target Privacy & Configuration
- `NSBluetoothAlwaysUsageDescription` / `NSBluetoothPeripheralUsageDescription` configured on watchOS target.
