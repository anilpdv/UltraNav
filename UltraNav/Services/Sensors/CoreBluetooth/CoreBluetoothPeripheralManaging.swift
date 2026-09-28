import CoreBluetooth
import Foundation

@MainActor
protocol CoreBluetoothPeripheralManaging: AnyObject {
    var identifier: UUID { get }
    var name: String? { get }
    var state: CBPeripheralState { get }
    var services: [CBService]? { get }
    var delegate: CBPeripheralDelegate? { get set }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    func readValue(for characteristic: CBCharacteristic)
}

extension CBPeripheral: CoreBluetoothPeripheralManaging {}
