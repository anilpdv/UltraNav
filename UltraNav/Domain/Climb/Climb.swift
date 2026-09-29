import Foundation

/// Domain model representing a detected and categorized climb on a route.
struct Climb: Identifiable, Equatable, Sendable, Codable {
    struct ID: Hashable, Sendable, Codable, RawRepresentable, CustomStringConvertible {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(routeID: UUID, climbIndex: Int) {
            self.rawValue = "\(routeID.uuidString.lowercased())-climb-\(climbIndex)"
        }

        var description: String { rawValue }
    }

    let id: ID
    let routeID: UUID
    let climbIndex: Int
    let totalClimbs: Int
    let startIndex: Int
    let endIndex: Int
    let startDistanceMeters: Double
    let endDistanceMeters: Double
    let startElevationMeters: Double
    let summitElevationMeters: Double
    let elevationGainMeters: Double
    let averageGradientRatio: Double
    let maximumGradientRatio: Double
    let category: ClimbCategory
    let gradientSlices: [ClimbGradientSlice]

    var lengthMeters: Double {
        max(0, endDistanceMeters - startDistanceMeters)
    }

    var averageGradientPercent: Double {
        averageGradientRatio * 100.0
    }

    var maximumGradientPercent: Double {
        maximumGradientRatio * 100.0
    }

    init(
        id: ID,
        routeID: UUID,
        climbIndex: Int,
        totalClimbs: Int,
        startIndex: Int,
        endIndex: Int,
        startDistanceMeters: Double,
        endDistanceMeters: Double,
        startElevationMeters: Double,
        summitElevationMeters: Double,
        elevationGainMeters: Double,
        averageGradientRatio: Double,
        maximumGradientRatio: Double,
        category: ClimbCategory,
        gradientSlices: [ClimbGradientSlice] = []
    ) {
        self.id = id
        self.routeID = routeID
        self.climbIndex = climbIndex
        self.totalClimbs = totalClimbs
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startDistanceMeters = startDistanceMeters
        self.endDistanceMeters = endDistanceMeters
        self.startElevationMeters = startElevationMeters
        self.summitElevationMeters = summitElevationMeters
        self.elevationGainMeters = elevationGainMeters
        self.averageGradientRatio = averageGradientRatio
        self.maximumGradientRatio = maximumGradientRatio
        self.category = category
        self.gradientSlices = gradientSlices
    }
}
