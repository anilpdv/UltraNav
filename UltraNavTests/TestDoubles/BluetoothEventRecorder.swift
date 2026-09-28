import Foundation
@testable import UltraNav

actor BluetoothEventRecorder {
    private(set) var events: [SensorServiceEvent] = []

    func record(_ event: SensorServiceEvent) {
        events.append(event)
    }

    func clear() {
        events.removeAll()
    }
}
