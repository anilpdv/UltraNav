import CoreBluetooth
import Foundation
import OSLog

@MainActor
final class BluetoothService: NSObject, SensorProviding, CoreBluetoothDelegateBridgeDelegate, PeripheralDelegateBridgeDelegate {
    nonisolated let events: AsyncStream<SensorServiceEvent>
    private let continuation: AsyncStream<SensorServiceEvent>.Continuation

    private let central: any CoreBluetoothManaging
    private let centralDelegateBridge: CoreBluetoothDelegateBridge
    private let clock: any ClockProviding
    private let packetParser: any SensorPacketParsing

    private(set) var availability: BluetoothAvailability = .unknown
    private(set) var scanState: SensorScanState = .idle
    private var activeScanRequest: SensorScanRequest?

    private var contexts: [SensorIdentifier: PeripheralContext] = [:]
    private var peripheralUUIDMap: [UUID: SensorIdentifier] = [:]

    private static func makeDefaultCentral() -> any CoreBluetoothManaging {
        #if targetEnvironment(simulator)
        if NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return NoOpCentralManager()
        }
        #endif
        return CBCentralManager(delegate: nil, queue: nil)
    }

    init(
        central: any CoreBluetoothManaging = BluetoothService.makeDefaultCentral(),
        centralDelegateBridge: CoreBluetoothDelegateBridge = CoreBluetoothDelegateBridge(),
        clock: any ClockProviding = SystemClock(),
        packetParser: any SensorPacketParsing = CyclingSensorPacketParser()
    ) {
        let pair = AsyncStream.makeStream(
            of: SensorServiceEvent.self,
            bufferingPolicy: .bufferingNewest(100)
        )
        self.events = pair.stream
        self.continuation = pair.continuation

        self.central = central
        self.centralDelegateBridge = centralDelegateBridge
        self.clock = clock
        self.packetParser = packetParser

        super.init()

        self.centralDelegateBridge.delegate = self
        self.central.delegate = centralDelegateBridge
        self.availability = CoreBluetoothMapper.mapAvailability(from: central.state)
    }

    deinit {
        continuation.finish()
    }

    // MARK: - SensorProviding

    func isAvailable() async -> Bool {
        availability == .poweredOn
    }

    func knownSensors() async -> [SensorDescriptor] {
        contexts.values
            .map(\.descriptor)
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    func startScanning(request: SensorScanRequest) async throws {
        guard availability == .poweredOn else {
            throw SensorServiceFailure.bluetoothUnavailable(availability)
        }

        guard scanState == .idle else {
            return
        }

        let serviceUUIDs = CoreBluetoothMapper.serviceUUIDs(for: request.sensorTypes)
        guard !serviceUUIDs.isEmpty else {
            throw SensorServiceFailure.invalidServiceState
        }

        activeScanRequest = request
        scanState = .starting
        continuation.yield(.scanStateChanged(.starting))

        central.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: request.allowDuplicateDiscoveries
            ]
        )

        scanState = .scanning
        continuation.yield(.scanStateChanged(.scanning))
    }

    func stopScanning() async {
        guard scanState == .starting || scanState == .scanning else {
            return
        }

        scanState = .stopping
        continuation.yield(.scanStateChanged(.stopping))

        central.stopScan()

        activeScanRequest = nil
        scanState = .idle
        continuation.yield(.scanStateChanged(.idle))
    }

    func connect(to sensor: SensorIdentifier) async throws {
        guard availability == .poweredOn else {
            throw SensorServiceFailure.bluetoothUnavailable(availability)
        }

        guard let context = contexts[sensor] else {
            throw SensorServiceFailure.unknownSensor(sensor)
        }

        switch context.connectionState {
        case .connecting, .connected, .discoveringServices, .discoveringCharacteristics, .subscribing, .ready:
            return
        case .disconnecting:
            throw SensorServiceFailure.invalidServiceState
        case .disconnected, .failed:
            break
        }

        context.disconnectWasRequested = false
        context.connectionState = .connecting
        continuation.yield(.connectionStateChanged(sensor: sensor, state: .connecting))

        central.connect(context.peripheral, options: nil)
    }

    func disconnect(from sensor: SensorIdentifier) async {
        guard let context = contexts[sensor] else {
            return
        }

        guard context.connectionState != .disconnected else {
            return
        }

        context.disconnectWasRequested = true
        context.connectionState = .disconnecting
        continuation.yield(.connectionStateChanged(sensor: sensor, state: .disconnecting))

        central.cancelPeripheralConnection(context.peripheral)
    }

    func disconnectAll() async {
        for context in contexts.values {
            guard context.connectionState != .disconnected else {
                continue
            }
            context.disconnectWasRequested = true
            context.connectionState = .disconnecting
            continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .disconnecting))
            central.cancelPeripheralConnection(context.peripheral)
        }
    }

    // MARK: - CoreBluetoothDelegateBridgeDelegate

    func bluetoothStateChanged(_ state: CBManagerState) {
        let mapped = CoreBluetoothMapper.mapAvailability(from: state)
        availability = mapped
        continuation.yield(.availabilityChanged(mapped))

        if mapped != .poweredOn {
            if scanState == .starting || scanState == .scanning {
                central.stopScan()
                scanState = .idle
                activeScanRequest = nil
                continuation.yield(.scanStateChanged(.idle))
            }

            for context in contexts.values {
                if context.connectionState != .disconnected {
                    context.connectionState = .disconnected
                    context.enabledNotificationCharacteristics.removeAll()
                    continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .disconnected))
                }
            }
        }
    }

    func peripheralDiscovered(
        _ peripheral: any CoreBluetoothPeripheralManaging,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) {
        let identifier = SensorIdentifier(rawValue: peripheral.identifier.uuidString)

        let advertisedServices = advertisedServiceUUIDs(from: advertisementData)
        var supportedTypes = CoreBluetoothMapper.sensorTypes(for: advertisedServices)

        // Fallback to active requested types if no service UUIDs in advertisement data
        if supportedTypes.isEmpty, let activeRequest = activeScanRequest {
            supportedTypes = activeRequest.sensorTypes
        }

        guard !supportedTypes.isEmpty else {
            return
        }

        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let displayName = advertisedName ?? peripheral.name

        let descriptor: SensorDescriptor
        if let existing = contexts[identifier] {
            let updatedName = displayName ?? existing.descriptor.name
            existing.descriptor = SensorDescriptor(
                id: identifier,
                name: updatedName,
                supportedTypes: existing.descriptor.supportedTypes.union(supportedTypes),
                isRemembered: existing.descriptor.isRemembered
            )
            descriptor = existing.descriptor
        } else {
            descriptor = SensorDescriptor(
                id: identifier,
                name: displayName,
                supportedTypes: supportedTypes,
                isRemembered: false
            )
            let bridge = PeripheralDelegateBridge()
            bridge.delegate = self
            let context = PeripheralContext(
                identifier: identifier,
                peripheral: peripheral,
                delegateBridge: bridge,
                descriptor: descriptor,
                connectionState: .disconnected,
                requestedTypes: supportedTypes
            )
            contexts[identifier] = context
            peripheralUUIDMap[peripheral.identifier] = identifier
        }

        continuation.yield(
            .sensorDiscovered(
                SensorDiscovery(
                    descriptor: descriptor,
                    signalStrength: CoreBluetoothMapper.normalizeRSSI(rssi),
                    advertisedName: advertisedName,
                    discoveredAt: clock.now
                )
            )
        )
    }

    func peripheralConnected(_ peripheral: any CoreBluetoothPeripheralManaging) {
        guard let context = context(for: peripheral) else { return }

        context.connectionState = .connected
        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .connected))

        peripheral.delegate = context.delegateBridge

        context.connectionState = .discoveringServices
        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .discoveringServices))

        let uuids = CoreBluetoothMapper.serviceUUIDs(for: context.requestedTypes)
        peripheral.discoverServices(uuids.isEmpty ? nil : uuids)
    }

    func peripheralConnectionFailed(_ peripheral: any CoreBluetoothPeripheralManaging, error: Error?) {
        guard let context = context(for: peripheral) else { return }

        context.connectionState = .failed
        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .failed))
        continuation.yield(.failed(.connectionFailed(context.identifier)))
    }

    func peripheralDisconnected(_ peripheral: any CoreBluetoothPeripheralManaging, error: Error?) {
        guard let context = context(for: peripheral) else { return }

        let wasRequested = context.disconnectWasRequested
        context.connectionState = .disconnected
        context.enabledNotificationCharacteristics.removeAll()

        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .disconnected))

        if !wasRequested {
            continuation.yield(.failed(.disconnectedUnexpectedly(context.identifier)))
        }

        context.disconnectWasRequested = false
    }

    // MARK: - PeripheralDelegateBridgeDelegate

    func peripheral(_ peripheral: any CoreBluetoothPeripheralManaging, discoveredServicesWith error: Error?) {
        guard let context = context(for: peripheral) else { return }

        if error != nil {
            failContext(context, failure: .serviceDiscoveryFailed(context.identifier))
            return
        }

        guard let services = peripheral.services, !services.isEmpty else {
            let expectedDesc = context.requestedTypes.map(\.rawValue).joined(separator: ", ")
            failContext(context, failure: .requiredServiceMissing(sensor: context.identifier, serviceIdentifier: expectedDesc))
            return
        }

        let supported = services.filter { CoreBluetoothMapper.isSupportedService($0.uuid) }
        guard !supported.isEmpty else {
            let expectedDesc = context.requestedTypes.map(\.rawValue).joined(separator: ", ")
            failContext(context, failure: .requiredServiceMissing(sensor: context.identifier, serviceIdentifier: expectedDesc))
            return
        }

        context.connectionState = .discoveringCharacteristics
        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .discoveringCharacteristics))

        for service in supported {
            context.discoveredServices[service.uuid.uuidString.uppercased()] = service
            let chars = CoreBluetoothMapper.characteristicUUIDs(for: service.uuid)
            peripheral.discoverCharacteristics(chars.isEmpty ? nil : chars, for: service)
        }
    }

    func peripheral(_ peripheral: any CoreBluetoothPeripheralManaging, discoveredCharacteristicsFor service: CBService, error: Error?) {
        guard let context = context(for: peripheral) else { return }

        if error != nil {
            failContext(context, failure: .characteristicDiscoveryFailed(context.identifier))
            return
        }

        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            failContext(context, failure: .characteristicDiscoveryFailed(context.identifier))
            return
        }

        var foundMeasurement = false
        for char in characteristics {
            let charID = char.uuid.uuidString.uppercased()
            context.discoveredCharacteristics[charID] = char

            if CoreBluetoothMapper.isMeasurementCharacteristic(char.uuid) {
                foundMeasurement = true
                if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                    context.connectionState = .subscribing
                    continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .subscribing))
                    peripheral.setNotifyValue(true, for: char)
                } else {
                    failContext(context, failure: .notificationSetupFailed(sensor: context.identifier, characteristicIdentifier: charID))
                    return
                }
            } else if CoreBluetoothMapper.shouldReadOnce(char.uuid) && char.properties.contains(.read) {
                peripheral.readValue(for: char)
            }
        }

        if !foundMeasurement && !characteristics.contains(where: { CoreBluetoothMapper.isMeasurementCharacteristic($0.uuid) }) {
            let anyMeasurement = context.discoveredCharacteristics.values.contains { CoreBluetoothMapper.isMeasurementCharacteristic($0.uuid) }
            if !anyMeasurement {
                let charDesc = "Measurement characteristic for \(service.uuid.uuidString)"
                failContext(context, failure: .requiredCharacteristicMissing(sensor: context.identifier, characteristicIdentifier: charDesc))
            }
        }
    }

    func peripheral(_ peripheral: any CoreBluetoothPeripheralManaging, updatedNotificationStateFor characteristic: any CoreBluetoothCharacteristicManaging, error: Error?) {
        guard let context = context(for: peripheral) else { return }

        let charID = characteristic.uuid.uuidString.uppercased()

        if error != nil || !characteristic.isNotifying {
            failContext(context, failure: .notificationSetupFailed(sensor: context.identifier, characteristicIdentifier: charID))
            return
        }

        context.enabledNotificationCharacteristics.insert(charID)

        if context.connectionState != .ready {
            context.connectionState = .ready
            continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .ready))
            continuation.yield(.sensorReady(context.descriptor))
        }
    }

    func peripheral(_ peripheral: any CoreBluetoothPeripheralManaging, updatedValueFor characteristic: any CoreBluetoothCharacteristicManaging, error: Error?) {
        guard let context = context(for: peripheral) else { return }

        let charID = characteristic.uuid.uuidString.uppercased()

        guard error == nil, let payload = characteristic.value, !payload.isEmpty else {
            continuation.yield(.failed(.malformedMeasurement(sensor: context.identifier, characteristicIdentifier: charID)))
            return
        }

        let packet = SensorMeasurementPacket(
            sensor: context.identifier,
            serviceIdentifier: characteristic.service?.uuid.uuidString.uppercased() ?? "",
            characteristicIdentifier: charID,
            payload: payload,
            receivedAt: clock.now
        )

        Task {
            do {
                let samples = try await self.packetParser.parse(packet)
                for sample in samples {
                    self.continuation.yield(.sampleReceived(sensor: context.identifier, sample: sample))
                }
            } catch {
                self.continuation.yield(.failed(.malformedMeasurement(sensor: context.identifier, characteristicIdentifier: charID)))
            }
        }
    }

    // MARK: - Private Helpers

    private func context(for peripheral: any CoreBluetoothPeripheralManaging) -> PeripheralContext? {
        if let id = peripheralUUIDMap[peripheral.identifier] {
            return contexts[id]
        }
        return nil
    }

    private func failContext(_ context: PeripheralContext, failure: SensorServiceFailure) {
        context.connectionState = .failed
        continuation.yield(.connectionStateChanged(sensor: context.identifier, state: .failed))
        continuation.yield(.failed(failure))
    }

    private func advertisedServiceUUIDs(from advertisementData: [String: Any]) -> [CBUUID] {
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            return serviceUUIDs
        }
        return []
    }
}
