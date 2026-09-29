import Foundation

/// Standard cycling climb categorization.
enum ClimbCategory: Int, Comparable, CaseIterable, Sendable, Codable {
    case uncategorized = 0
    case category4 = 1
    case category3 = 2
    case category2 = 3
    case category1 = 4
    case horsCategorie = 5

    static func < (lhs: ClimbCategory, rhs: ClimbCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Default display title.
    var displayName: String {
        switch self {
        case .uncategorized: return "Climb"
        case .category4: return "Cat 4"
        case .category3: return "Cat 3"
        case .category2: return "Cat 2"
        case .category1: return "Cat 1"
        case .horsCategorie: return "HC"
        }
    }
}
