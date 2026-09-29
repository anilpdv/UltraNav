import Foundation
#if canImport(WatchKit)
import WatchKit
#endif

@MainActor
final class WatchHapticService: HapticProviding {
    init() {}

    func play(_ pattern: HapticPattern) async {
        #if canImport(WatchKit) && os(watchOS)
        let device = WKInterfaceDevice.current()
        switch pattern {
        case .rideStarted:
            device.play(.start)
        case .ridePaused:
            device.play(.stop)
        case .rideResumed:
            device.play(.start)
        case .rideFinished:
            device.play(.success)
        case .turnApproaching:
            device.play(.directionUp)
        case .turnImmediate:
            device.play(.notification)
        case .possibleDeviation:
            device.play(.retry)
        case .offRoute:
            device.play(.failure)
        case .routeRejoined:
            device.play(.success)
        case .climbApproaching:
            device.play(.directionUp)
        case .climbStarted:
            device.play(.start)
        case .climbCompleted:
            device.play(.success)
        case .error:
            device.play(.failure)
        }
        #endif
    }
}
