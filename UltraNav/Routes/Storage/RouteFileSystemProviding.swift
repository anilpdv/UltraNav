import Foundation

/// Protocol abstracting file system interactions for RouteStore to enable test isolation.
public protocol RouteFileSystemProviding: Sendable {
    func fileExists(at url: URL) -> Bool
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func createDirectory(at url: URL) throws
    func readData(from url: URL) throws -> Data
    func writeData(_ data: Data, to url: URL, atomically: Bool) throws
    func removeItem(at url: URL) throws
}

public final class StandardRouteFileSystem: RouteFileSystemProviding, @unchecked Sendable {
    private let fileManager = FileManager.default

    public init() {}

    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    public func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func readData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func writeData(_ data: Data, to url: URL, atomically: Bool) throws {
        try data.write(to: url, options: atomically ? .atomic : [])
    }

    public func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}
