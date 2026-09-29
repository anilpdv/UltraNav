import Foundation

/// Records elements consumed from an arbitrary AsyncSequence into a thread-safe buffer.
actor AsyncSequenceRecorder<Element: Sendable> {
    private(set) var elements: [Element] = []

    func record(_ element: Element) {
        elements.append(element)
    }

    var count: Int {
        elements.count
    }

    var latest: Element? {
        elements.last
    }

    func clear() {
        elements.removeAll()
    }
}
