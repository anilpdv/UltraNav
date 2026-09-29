import Foundation

/// Protocol for safely reading data from various RouteImportSource types.
public protocol RouteSourceReading: Sendable {
    func read(from source: RouteImportSource) async throws -> RouteSourceContent
}

public enum RouteSourceReadFailure: Error, Equatable, Sendable {
    case fileNotFound(URL)
    case resourceNotFound(name: String)
    case unreadableData(reason: String)
}

public final class StandardRouteSourceReader: RouteSourceReading, Sendable {
    public init() {}

    public func read(from source: RouteImportSource) async throws -> RouteSourceContent {
        switch source {
        case .fileURL(let url):
            do {
                let data = try Data(contentsOf: url)
                let name = url.deletingPathExtension().lastPathComponent
                let sourceOrigin = RouteSource.importedGPX(originalFileName: url.lastPathComponent)
                return RouteSourceContent(data: data, source: sourceOrigin, fallbackName: name)
            } catch {
                throw RouteSourceReadFailure.fileNotFound(url)
            }

        case .data(let data, let originalFileName):
            let name = originalFileName?.components(separatedBy: ".").first ?? "Imported Course"
            let sourceOrigin = RouteSource.importedGPX(originalFileName: originalFileName ?? "imported.gpx")
            return RouteSourceContent(data: data, source: sourceOrigin, fallbackName: name)

        case .bundled(let resourceName, let bundle):
            if let url = bundle.url(forResource: resourceName, withExtension: "gpx") ?? bundle.url(forResource: resourceName, withExtension: nil) {
                do {
                    let data = try Data(contentsOf: url)
                    let sourceOrigin = RouteSource.bundled(resourceName: resourceName)
                    return RouteSourceContent(data: data, source: sourceOrigin, fallbackName: resourceName)
                } catch {
                    throw RouteSourceReadFailure.unreadableData(reason: error.localizedDescription)
                }
            } else {
                throw RouteSourceReadFailure.resourceNotFound(name: resourceName)
            }
        }
    }
}
