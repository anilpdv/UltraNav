import Foundation
@preconcurrency import CoreBluetooth

@MainActor
protocol CoreBluetoothDelegateBridgeDelegate: AnyObject {
    func bluetoothStateChanged(
        _ state: CBManagerState
    )

    func peripheralDiscovered(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        advertisementData: [String: Any],
        rssi: NSNumber
    )

    func peripheralConnected(
        _ peripheral: any CoreBluetoothPeripheralManaging
    )

    func peripheralConnectionFailed(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        error: Error?
    )

    func peripheralDisconnected(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        error: Error?
    )
}

final class CoreBluetoothDelegateBridge: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    weak var delegate: (any CoreBluetoothDelegateBridgeDelegate)?

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor [weak self] in
            self?.delegate?.bluetoothStateChanged(state)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        nonisolated(unsafe) let adData = advertisementData
        Task { @MainActor [weak self] in
            self?.delegate?.peripheralDiscovered(
                peripheral,
                advertisementData: adData,
                rssi: RSSI
            )
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheralConnected(peripheral)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheralConnectionFailed(peripheral, error: error)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheralDisconnected(peripheral, error: error)
        }
    }
}
