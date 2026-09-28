import Foundation

struct CompletedWorkoutReference: Equatable, Sendable {
    let identifier: UUID
    let startDate: Date
    let endDate: Date
}
