import Foundation
import Testing
@testable import UltraNav

@Suite("BluetoothConcurrency Tests")
struct BluetoothConcurrencyTests {
    @Test("Bluetooth mock event channel distributes sensor events safely")
    func testBluetoothMockEvents() async {
        let fake = FakeSensorProvider()
        let received = LockedValue<[SensorServiceEvent]>([])

        let task = Task {
            for await event in fake.events {
                received.withLock { $0.append(event) }
            }
        }

        fake.send(.availabilityChanged(.poweredOn))
        fake.send(.sampleReceived(sensor: SensorIdentifier(rawValue: "power-1"), sample: .power(watts: 250, timestamp: Date())))

        try? await Task.sleep(nanoseconds: 30_000_000)
        fake.finishEvents()
        task.cancel()

        #expect(received.get().count >= 1)
    }
}
