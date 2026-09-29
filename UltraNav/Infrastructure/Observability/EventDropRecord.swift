import Foundation

enum EventStreamName: String, CaseIterable, Equatable, Hashable, Sendable {
    case location
    case workoutLifecycle
    case workoutMetrics
    case sensorLifecycle
    case sensorMeasurements
    case rideSnapshots
    case metricsSnapshots
    case navigationSnapshots
    case navigationNotifications
    case climbSnapshots
    case climbNotifications
    case presentationEvents
}

enum EventClass: String, CaseIterable, Equatable, Hashable, Sendable {
    case lifecycle
    case measurement
    case snapshot
    case notification
}

struct EventDropRecord: Equatable, Sendable {
    let stream: EventStreamName
    let droppedCount: Int
    let bufferCapacity: Int
    let eventClass: EventClass

    init(
        stream: EventStreamName,
        droppedCount: Int,
        bufferCapacity: Int,
        eventClass: EventClass
    ) {
        self.stream = stream
        self.droppedCount = droppedCount
        self.bufferCapacity = bufferCapacity
        self.eventClass = eventClass
    }
}
