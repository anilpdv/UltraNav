import Foundation

/// Protocol for encoding and decoding route storage records and index files.
public protocol RouteStorageCodec: Sendable {
    func encodeRecord(_ record: RouteStorageRecord) throws -> Data
    func decodeRecord(from data: Data) throws -> RouteStorageRecord

    func encodeIndex(_ index: RouteStoreIndex) throws -> Data
    func decodeIndex(from data: Data) throws -> RouteStoreIndex
}

public final class JSONRouteStorageCodec: RouteStorageCodec, Sendable {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    public func encodeRecord(_ record: RouteStorageRecord) throws -> Data {
        try encoder.encode(record)
    }

    public func decodeRecord(from data: Data) throws -> RouteStorageRecord {
        try decoder.decode(RouteStorageRecord.self, from: data)
    }

    public func encodeIndex(_ index: RouteStoreIndex) throws -> Data {
        try encoder.encode(index)
    }

    public func decodeIndex(from data: Data) throws -> RouteStoreIndex {
        try decoder.decode(RouteStoreIndex.self, from: data)
    }
}
