import Foundation

/// Safe, bounds-checked binary cursor for parsing Bluetooth Low Energy sensor measurement payloads.
struct SensorPacketCursor: Sendable {
    private let data: Data
    private(set) var offset: Int = 0

    init(data: Data) {
        self.data = data
        self.offset = 0
    }

    var remainingBytes: Int {
        max(0, data.count - offset)
    }

    var isAtEnd: Bool {
        offset >= data.count
    }

    mutating func readUInt8() throws -> UInt8 {
        guard offset < data.count else {
            throw SensorPacketParsingFailure.insufficientBytes
        }
        let byte = data[data.startIndex + offset]
        offset += 1
        return byte
    }

    mutating func readUInt16LE() throws -> UInt16 {
        guard offset + 2 <= data.count else {
            throw SensorPacketParsingFailure.insufficientBytes
        }
        let b0 = UInt16(data[data.startIndex + offset])
        let b1 = UInt16(data[data.startIndex + offset + 1])
        offset += 2
        return b0 | (b1 << 8)
    }

    mutating func readInt16LE() throws -> Int16 {
        let uValue = try readUInt16LE()
        return Int16(bitPattern: uValue)
    }

    mutating func readUInt24LE() throws -> UInt32 {
        guard offset + 3 <= data.count else {
            throw SensorPacketParsingFailure.insufficientBytes
        }
        let b0 = UInt32(data[data.startIndex + offset])
        let b1 = UInt32(data[data.startIndex + offset + 1])
        let b2 = UInt32(data[data.startIndex + offset + 2])
        offset += 3
        return b0 | (b1 << 8) | (b2 << 16)
    }

    mutating func readUInt32LE() throws -> UInt32 {
        guard offset + 4 <= data.count else {
            throw SensorPacketParsingFailure.insufficientBytes
        }
        let b0 = UInt32(data[data.startIndex + offset])
        let b1 = UInt32(data[data.startIndex + offset + 1])
        let b2 = UInt32(data[data.startIndex + offset + 2])
        let b3 = UInt32(data[data.startIndex + offset + 3])
        offset += 4
        return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    }

    mutating func skip(bytes: Int) throws {
        guard bytes >= 0, offset + bytes <= data.count else {
            throw SensorPacketParsingFailure.insufficientBytes
        }
        offset += bytes
    }
}
