import Foundation
import Testing
@testable import UltraNav

@Suite("FailureClassification Tests")
struct FailureClassificationTests {
    @Test("RideFailureMapper properly classifies workout and location failures")
    func testRideFailureClassification() {
        let mapper = RideFailureMapper()
        let context = FailureContext(operation: .ridePreparation, rideState: .preparing)

        let locAuth = mapper.classify(failure: .locationPermissionRequired, context: context)
        #expect(locAuth.id == .locationPermissionDenied)
        #expect(locAuth.severity == .high)
        #expect(locAuth.recoverability == .userActionRequired)
        #expect(locAuth.suggestedActions.contains(.openSystemSettings))

        let workoutStart = mapper.classify(failure: .workoutStartFailed, context: context)
        #expect(workoutStart.id == .workoutStartFailed)
        #expect(workoutStart.severity == .critical)
        #expect(workoutStart.impact.contains(.blocksRideStart))
    }

    @Test("NavigationFailureMapper classifies route missing correctly")
    func testNavigationFailureClassification() {
        let mapper = NavigationFailureMapper()
        let context = FailureContext(operation: .navigationMatching, rideState: .active)

        let routeMissing = mapper.classify(failure: .routeUnavailable, context: context)
        #expect(routeMissing.id == .navigationRouteMissing)
        #expect(routeMissing.severity == .high)
        #expect(routeMissing.suggestedActions.contains(.selectAnotherRoute))
        #expect(routeMissing.suggestedActions.contains(.continueWithoutNavigation))
    }

    @Test("SensorFailureMapper classifies disconnection as retryable degradation")
    func testSensorFailureClassification() {
        let mapper = SensorServiceFailureMapper()
        let sensorID = SensorIdentifier(rawValue: "hr-1")
        let context = FailureContext(operation: .sensorMeasurement, rideState: .active, sensorID: sensorID)

        let disconnect = mapper.classify(failure: .disconnectedUnexpectedly(sensorID), context: context)
        #expect(disconnect.id == .sensorDisconnected)
        #expect(disconnect.severity == .warning)
        #expect(disconnect.impact.contains(.degradesActiveRide))
        #expect(disconnect.suggestedActions.contains(.reconnectSensor(sensorID)))
        #expect(disconnect.suggestedActions.contains(.continueWithoutSensors))
    }
}
