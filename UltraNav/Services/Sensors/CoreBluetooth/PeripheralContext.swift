import CoreBluetooth
import Foundation

@MainActor
final class PeripheralContext {
    let identifier: SensorIdentifier
    let peripheral: any CoreBluetoothPeripheralManaging
    let delegateBridge: PeripheralDelegateBridge
    var descriptor: SensorDescriptor
    var connectionState: SensorConnectionState
    var requestedTypes: Set<SensorType>
    var discoveredServices: [String: CBService]
    var discoveredCharacteristics: [String: any CoreBluetoothCharacteristicManaging]
    var enabledNotificationCharacteristics: Set<String>
    var disconnectWasRequested: Bool

    init(
        identifier: SensorIdentifier,
        peripheral: any CoreBluetoothPeripheralManaging,
        delegateBridge: PeripheralDelegateBridge,
        descriptor: SensorDescriptor,
        connectionState: SensorConnectionState = .disconnected,
        requestedTypes: Set<SensorType>
    ) {
        self.identifier = identifier
        self.peripheral = peripheral
        self.delegateBridge = delegateBridge
        self.descriptor = descriptor
        self.connectionState = connectionState
        self.requestedTypes = requestedTypes
        self.discoveredServices = [:]
        self.discoveredCharacteristics = [:]
        self.enabledNotificationCharacteristics = []
        self.disconnectWasRequested = false
    }
}
