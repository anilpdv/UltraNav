import Foundation
@preconcurrency import CoreBluetooth

@MainActor
protocol PeripheralDelegateBridgeDelegate: AnyObject {
    func peripheral(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        discoveredServicesWith error: Error?
    )

    func peripheral(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        discoveredCharacteristicsFor service: CBService,
        error: Error?
    )

    func peripheral(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        updatedNotificationStateFor characteristic: any CoreBluetoothCharacteristicManaging,
        error: Error?
    )

    func peripheral(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        updatedValueFor characteristic: any CoreBluetoothCharacteristicManaging,
        error: Error?
    )
}

final class PeripheralDelegateBridge: NSObject, CBPeripheralDelegate, @unchecked Sendable {
    weak var delegate: (any PeripheralDelegateBridgeDelegate)?

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheral(peripheral, discoveredServicesWith: error)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheral(
                peripheral,
                discoveredCharacteristicsFor: service,
                error: error
            )
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheral(
                peripheral,
                updatedNotificationStateFor: characteristic,
                error: error
            )
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.peripheral(
                peripheral,
                updatedValueFor: characteristic,
                error: error
            )
        }
    }
}
