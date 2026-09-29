import Foundation

struct FunctionalThresholdPower: Equatable, Codable, Sendable {
    let watts: Double

    init?(watts: Double) {
        guard watts.isFinite, watts > 0 else {
            return nil
        }
        self.watts = watts
    }
}
