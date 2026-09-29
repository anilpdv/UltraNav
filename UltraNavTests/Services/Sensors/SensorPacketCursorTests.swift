import XCTest
@testable import UltraNav

final class SensorPacketCursorTests: XCTestCase {
    func test_readUInt8_success() throws {
        var cursor = SensorPacketCursor(data: Data([0x12, 0x34]))
        XCTAssertEqual(try cursor.readUInt8(), 0x12)
        XCTAssertEqual(try cursor.readUInt8(), 0x34)
        XCTAssertTrue(cursor.isAtEnd)
    }

    func test_readUInt16LE_success() throws {
        var cursor = SensorPacketCursor(data: Data([0x34, 0x12]))
        XCTAssertEqual(try cursor.readUInt16LE(), 0x1234)
        XCTAssertTrue(cursor.isAtEnd)
    }

    func test_readInt16LE_negativeAndPositive() throws {
        // -500 in Int16 LE: 0xFE0C -> bytes [0x0C, 0xFE]
        var cursor = SensorPacketCursor(data: Data([0x0C, 0xFE, 0x50, 0x01]))
        XCTAssertEqual(try cursor.readInt16LE(), -500)
        XCTAssertEqual(try cursor.readInt16LE(), 336)
    }

    func test_readUInt32LE_success() throws {
        var cursor = SensorPacketCursor(data: Data([0x78, 0x56, 0x34, 0x12]))
        XCTAssertEqual(try cursor.readUInt32LE(), 0x12345678)
        XCTAssertTrue(cursor.isAtEnd)
    }

    func test_skipBytes_success() throws {
        var cursor = SensorPacketCursor(data: Data([0x01, 0x02, 0x03, 0x04]))
        try cursor.skip(bytes: 2)
        XCTAssertEqual(try cursor.readUInt8(), 0x03)
    }

    func test_insufficientBytes_throwsError() {
        var cursor = SensorPacketCursor(data: Data([0x01]))
        XCTAssertThrowsError(try cursor.readUInt16LE())
        XCTAssertThrowsError(try cursor.skip(bytes: 5))
    }
}
