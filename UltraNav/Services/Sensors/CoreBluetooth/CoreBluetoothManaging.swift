import CoreBluetooth
import Foundation

@MainActor
protocol CoreBluetoothManaging: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var state: CBManagerState { get }
    var isScanning: Bool { get }

    func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String: Any]?
    )

    func stopScan()

    func connect(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        options: [String: Any]?
    )

    func cancelPeripheralConnection(
        _ peripheral: any CoreBluetoothPeripheralManaging
    )

    func retrievePeripherals(
        withIdentifiers identifiers: [UUID]
    ) -> [any CoreBluetoothPeripheralManaging]

    func retrieveConnectedPeripherals(
        withServices serviceUUIDs: [CBUUID]
    ) -> [any CoreBluetoothPeripheralManaging]
}

extension CBCentralManager: CoreBluetoothManaging {
    func connect(_ peripheral: any CoreBluetoothPeripheralManaging, options: [String: Any]?) {
        if let cbPeripheral = peripheral as? CBPeripheral {
            self.connect(cbPeripheral, options: options)
        }
    }

    func cancelPeripheralConnection(_ peripheral: any CoreBluetoothPeripheralManaging) {
        if let cbPeripheral = peripheral as? CBPeripheral {
            self.cancelPeripheralConnection(cbPeripheral)
        }
    }

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [any CoreBluetoothPeripheralManaging] {
        let items: [CBPeripheral] = self.retrievePeripherals(withIdentifiers: identifiers)
        return items
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [any CoreBluetoothPeripheralManaging] {
        let items: [CBPeripheral] = self.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        return items
    }
}

final class NoOpCentralManager: CoreBluetoothManaging {
    weak var delegate: CBCentralManagerDelegate?
    var state: CBManagerState = .poweredOff
    var isScanning: Bool = false

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {}
    func stopScan() {}
    func connect(_ peripheral: any CoreBluetoothPeripheralManaging, options: [String: Any]?) {}
    func cancelPeripheralConnection(_ peripheral: any CoreBluetoothPeripheralManaging) {}
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [any CoreBluetoothPeripheralManaging] { [] }
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [any CoreBluetoothPeripheralManaging] { [] }
}
