import Foundation
@testable import UltraNav

final class InMemoryRouteFileSystem: RouteFileSystemProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [URL: Data] = [:]
    private var directories: Set<URL> = []

    var nextReadFailure: (any Error)?
    var nextWriteFailure: (any Error)?
    var nextDeleteFailure: (any Error)?

    init(initialFiles: [URL: Data] = [:]) {
        self.files = initialFiles
    }

    func fileExists(at url: URL) -> Bool {
        lock.withLock {
            files[url] != nil || directories.contains(url)
        }
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        lock.withLock {
            Array(files.keys.filter { $0.deletingLastPathComponent() == url })
        }
    }

    func createDirectory(at url: URL) throws {
        lock.withLock {
            directories.insert(url)
        }
    }

    func readData(from url: URL) throws -> Data {
        try lock.withLock {
            if let failure = nextReadFailure {
                nextReadFailure = nil
                throw failure
            }
            guard let data = files[url] else {
                throw NSError(domain: "InMemoryRouteFileSystem", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found: \(url.path)"])
            }
            return data
        }
    }

    func writeData(_ data: Data, to url: URL, atomically: Bool) throws {
        try lock.withLock {
            if let failure = nextWriteFailure {
                nextWriteFailure = nil
                throw failure
            }
            files[url] = data
        }
    }

    func removeItem(at url: URL) throws {
        try lock.withLock {
            if let failure = nextDeleteFailure {
                nextDeleteFailure = nil
                throw failure
            }
            guard files.removeValue(forKey: url) != nil else {
                throw NSError(domain: "InMemoryRouteFileSystem", code: 404, userInfo: [NSLocalizedDescriptionKey: "Cannot remove missing file: \(url.path)"])
            }
        }
    }

    func clear() {
        lock.withLock {
            files.removeAll()
            directories.removeAll()
            nextReadFailure = nil
            nextWriteFailure = nil
            nextDeleteFailure = nil
        }
    }
}
