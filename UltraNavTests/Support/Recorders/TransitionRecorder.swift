import Foundation

/// Actor capturing discrete state transitions for engine and coordinator test assertions.
actor TransitionRecorder<Transition: Equatable & Sendable> {
    private(set) var transitions: [Transition] = []

    func record(_ transition: Transition) {
        transitions.append(transition)
    }

    var count: Int {
        transitions.count
    }

    var latest: Transition? {
        transitions.last
    }

    var all: [Transition] {
        transitions
    }

    func clear() {
        transitions.removeAll()
    }
}
