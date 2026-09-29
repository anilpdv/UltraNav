import Foundation

struct DegradationViewState: Equatable, Sendable {
    let title: String
    let symbol: String
    let degradation: Degradation

    init(title: String, symbol: String, degradation: Degradation) {
        self.title = title
        self.symbol = symbol
        self.degradation = degradation
    }
}
