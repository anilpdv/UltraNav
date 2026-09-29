import Foundation
@testable import UltraNav

final class FakeRouteFileSystem: RouteFileSystemProviding, @unchecked Sendable {
    private var files: [URL: Data] = [:]
    var shouldFailRead: Bool = false
    var shouldFailWrite: Bool = false
    var shouldFailDelete: Bool = false

    init(files: [URL: Data] = [:]) {
        self.files = files
    }

    func fileExists(at url: URL) -> Bool {
        files[url] != nil
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        Array(files.keys)
    }

    func createDirectory(at url: URL) throws {}

    func readData(from url: URL) throws -> Data {
        if shouldFailRead {
            throw NSError(domain: "FakeRouteFileSystem", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated read error"])
        }
        guard let data = files[url] else {
            throw NSError(domain: "FakeRouteFileSystem", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        return data
    }

    func writeData(_ data: Data, to url: URL, atomically: Bool) throws {
        if shouldFailWrite {
            throw NSError(domain: "FakeRouteFileSystem", code: 2, userInfo: [NSLocalizedDescriptionKey: "Simulated write error"])
        }
        files[url] = data
    }

    func removeItem(at url: URL) throws {
        if shouldFailDelete {
            throw NSError(domain: "FakeRouteFileSystem", code: 3, userInfo: [NSLocalizedDescriptionKey: "Simulated delete error"])
        }
        guard files.removeValue(forKey: url) != nil else {
            throw NSError(domain: "FakeRouteFileSystem", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
    }
}
