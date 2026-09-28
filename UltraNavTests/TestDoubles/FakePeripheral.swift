import CoreBluetooth
import Foundation
@testable import UltraNav

@MainActor
final class FakePeripheral: CoreBluetoothPeripheralManaging {
    let identifier: UUID
    var name: String?
    var state: CBPeripheralState = .disconnected
    var services: [CBService]?
    weak var delegate: CBPeripheralDelegate?

    private(set) var discoverServicesCalls: [[CBUUID]?] = []
    private(set) var discoverCharacteristicsCalls: [(service: CBService, uuids: [CBUUID]?)] = []
    private(set) var notifyValues: [(char: CBCharacteristic, enabled: Bool)] = []
    private(set) var readValues: [CBCharacteristic] = []

    init(identifier: UUID = UUID(), name: String? = "Fake Sensor") {
        self.identifier = identifier
        self.name = name
    }

    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalls.append(serviceUUIDs)
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        discoverCharacteristicsCalls.append((service, characteristicUUIDs))
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        notifyValues.append((characteristic, enabled))
    }

    func readValue(for characteristic: CBCharacteristic) {
        readValues.append(characteristic)
    }
}
