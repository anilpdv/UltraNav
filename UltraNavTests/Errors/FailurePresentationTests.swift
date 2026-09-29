import Foundation
import Testing
@testable import UltraNav

@Suite("FailurePresentation Tests")
struct FailurePresentationTests {
    @Test("FailurePresentationMapper maps FailureRecord to actionable FailureViewState")
    func testPresentationMapping() {
        let mapper = FailurePresentationMapper()

        let sensorID = SensorIdentifier(rawValue: "power-1")
        let record = FailureFactory.makeRecord(
            failureID: .sensorDisconnected,
            failure: .sensors(.disconnectedUnexpectedly(sensorID)),
            severity: .warning,
            suggestedActions: [.reconnectSensor(sensorID), .continueWithoutSensors]
        )

        let viewState = mapper.map(record: record)
        #expect(viewState.title == "Sensor Disconnected")
        #expect(viewState.severity == .warning)
        #expect(viewState.isDismissable)
        #expect(viewState.primaryAction?.title == "Reconnect")
        #expect(viewState.primaryAction?.action == .reconnectSensor(sensorID))
        #expect(viewState.secondaryAction?.title == "Continue Without Sensors")
    }

    @Test("Critical failures are marked non-dismissable")
    func testCriticalFailurePresentation() {
        let mapper = FailurePresentationMapper()

        let record = FailureFactory.makeRecord(
            failureID: .workoutStartFailed,
            failure: .workout(.startFailed),
            severity: .critical,
            suggestedActions: [.retry, .resetRide]
        )

        let viewState = mapper.map(record: record)
        #expect(!viewState.isDismissable)
        #expect(viewState.primaryAction?.title == "Retry")
        #expect(viewState.secondaryAction?.title == "Reset Ride")
        #expect(viewState.secondaryAction?.isDestructive == true)
    }
}
