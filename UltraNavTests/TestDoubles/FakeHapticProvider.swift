import Foundation
@testable import UltraNav

actor FakeHapticProvider: HapticProviding {
    private(set) var playedPatterns: [HapticPattern] = []

    func play(_ pattern: HapticPattern) async {
        playedPatterns.append(pattern)
    }

    func reset() {
        playedPatterns.removeAll()
    }
}
