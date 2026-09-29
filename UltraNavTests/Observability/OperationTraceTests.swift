import Testing
import Foundation
@testable import UltraNav

@Suite("OperationTrace Tests")
struct OperationTraceTests {
    @Test("OperationTracer records start and success with monotonic duration")
    func testOperationTracerSuccess() async throws {
        let center = FakeObservabilityCenter()
        let monoClock = TestMonotonicClock()
        let tracer = OperationTracer(observability: center, monotonicClock: monoClock)

        let opID = OperationID()
        let parentID = OperationID()

        let result = try await tracer.trace(
            operation: .routeNormalize,
            operationID: opID,
            parentOperationID: parentID,
            attempt: 1
        ) {
            monoClock.advance(milliseconds: 150)
            return "normalized"
        }

        #expect(result == "normalized")

        let events = await center.recordedEvents
        #expect(events.count == 2)

        if case .operationStarted(let startTrace) = events[0].kind {
            #expect(startTrace.operation == .routeNormalize)
            #expect(startTrace.operationID == opID)
            #expect(startTrace.parentOperationID == parentID)
            #expect(startTrace.attempt == 1)
        } else {
            Issue.record("Expected operationStarted event")
        }

        if case .operationFinished(let finishTrace) = events[1].kind {
            #expect(finishTrace.operation == .routeNormalize)
            #expect(finishTrace.outcome == .succeeded)
            #expect(finishTrace.durationMilliseconds == 150.0)
        } else {
            Issue.record("Expected operationFinished event")
        }
    }

    @Test("OperationTracer records cancellation distinctly")
    func testOperationTracerCancellation() async {
        let center = FakeObservabilityCenter()
        let monoClock = TestMonotonicClock()
        let tracer = OperationTracer(observability: center, monotonicClock: monoClock)

        do {
            _ = try await tracer.trace(operation: .gpxParse) {
                monoClock.advance(milliseconds: 50)
                throw CancellationError()
            }
            Issue.record("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let events = await center.recordedEvents
        #expect(events.count == 2)
        if case .operationFinished(let finishTrace) = events[1].kind {
            #expect(finishTrace.outcome == .cancelled)
        } else {
            Issue.record("Expected operationFinished with cancelled outcome")
        }
    }
}
