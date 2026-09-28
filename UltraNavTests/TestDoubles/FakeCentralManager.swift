import CoreBluetooth
import Foundation
@testable import UltraNav

@MainActor
final class FakeCentralManager: CoreBluetoothManaging {
    weak var delegate: CBCentralManagerDelegate?
    var state: CBManagerState = .unknown
    private(set) var isScanning = false
    private(set) var scanRequests: [[CBUUID]?] = []
    private(set) var scanOptions: [[String: Any]?] = []
    private(set) var stopScanCallCount = 0
    private(set) var connectedPeripherals: [any CoreBluetoothPeripheralManaging] = []
    private(set) var cancelledPeripherals: [any CoreBluetoothPeripheralManaging] = []

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        isScanning = true
        scanRequests.append(serviceUUIDs)
        scanOptions.append(options)
    }

    func stopScan() {
        isScanning = false
        stopScanCallCount += 1
    }

    func connect(_ peripheral: any CoreBluetoothPeripheralManaging, options: [String: Any]?) {
        connectedPeripherals.append(peripheral)
    }

    func cancelPeripheralConnection(_ peripheral: any CoreBluetoothPeripheralManaging) {
        cancelledPeripherals.append(peripheral)
    }

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [any CoreBluetoothPeripheralManaging] {
        []
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [any CoreBluetoothPeripheralManaging] {
        []
    }

    func setState(_ newState: CBManagerState) {
        self.state = newState
    }
}
