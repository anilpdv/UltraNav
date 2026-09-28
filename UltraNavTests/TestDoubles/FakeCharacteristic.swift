import CoreBluetooth
import Foundation
@testable import UltraNav

@MainActor
final class FakeCharacteristic: CoreBluetoothCharacteristicManaging {
    let uuid: CBUUID
    var service: CBService?
    var value: Data?
    var isNotifying: Bool
    var properties: CBCharacteristicProperties

    init(
        uuid: CBUUID,
        service: CBService? = nil,
        value: Data? = nil,
        isNotifying: Bool = false,
        properties: CBCharacteristicProperties = [.notify, .read]
    ) {
        self.uuid = uuid
        self.service = service
        self.value = value
        self.isNotifying = isNotifying
        self.properties = properties
    }
}
