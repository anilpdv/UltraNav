import Foundation

/// Classifies signed turn angles into discrete navigation maneuvers.
enum ManeuverClassifier {
    /// Normalizes any angle difference in degrees to the signed range [-180.0, 180.0).
    /// Positive values indicate a right turn; negative values indicate a left turn.
    static func normalizeAngleDifference(_ degrees: Double) -> Double {
        var diff = degrees.truncatingRemainder(dividingBy: 360.0)
        if diff > 180.0 {
            diff -= 360.0
        } else if diff <= -180.0 {
            diff += 360.0
        }
        return diff
    }

    /// Classifies a signed turn angle (in degrees) into a standard `NavigationManeuver`.
    /// - Parameter turnAngleDegrees: Signed angular change (-180° to +180°).
    /// - Returns: Categorized `NavigationManeuver`.
    static func classify(turnAngleDegrees: Double) -> NavigationManeuver {
        let angle = normalizeAngleDifference(turnAngleDegrees)
        let absAngle = abs(angle)

        if absAngle < 20.0 {
            return .continueStraight
        } else if absAngle >= 160.0 {
            return .uTurn
        } else if angle > 0 {
            // Right turns
            if absAngle < 45.0 {
                return .slightRight
            } else if absAngle < 120.0 {
                return .right
            } else {
                return .sharpRight
            }
        } else {
            // Left turns
            if absAngle < 45.0 {
                return .slightLeft
            } else if absAngle < 120.0 {
                return .left
            } else {
                return .sharpLeft
            }
        }
    }

    /// Generates a default semantic instruction string from a maneuver.
    static func defaultInstruction(for maneuver: NavigationManeuver) -> String {
        switch maneuver {
        case .continueStraight:
            return "Continue straight"
        case .slightLeft:
            return "Slight left"
        case .left:
            return "Turn left"
        case .sharpLeft:
            return "Sharp left"
        case .slightRight:
            return "Slight right"
        case .right:
            return "Turn right"
        case .sharpRight:
            return "Sharp right"
        case .uTurn:
            return "Make a U-turn"
        case .arrive:
            return "Arrive at destination"
        case .unknown:
            return "Continue"
        }
    }
}
