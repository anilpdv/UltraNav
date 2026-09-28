import CoreBluetooth
import Foundation

@MainActor
protocol CoreBluetoothCharacteristicManaging: AnyObject {
    var uuid: CBUUID { get }
    var service: CBService? { get }
    var value: Data? { get }
    var isNotifying: Bool { get }
    var properties: CBCharacteristicProperties { get }
}

extension CBCharacteristic: CoreBluetoothCharacteristicManaging {}
