import XCTest
@testable import UltraNav

final class ParsedRouteValidatorTests: XCTestCase {
    private var validator: ParsedRouteValidator!

    override func setUp() {
        super.setUp()
        validator = ParsedRouteValidator()
    }

    func testValidateEmptyDocumentThrowsNoUsableCoordinates() {
        let doc = GPXParsedDocument()
        XCTAssertThrowsError(try validator.validate(document: doc, policy: .default)) { error in
            XCTAssertEqual(error as? ParsedRouteValidationFailure, .noUsableCoordinates)
        }
    }

    func testValidateInsufficientPointsThrowsError() {
        let doc = GPXParsedDocument(tracks: [
            GPXParsedTrack(segments: [
                GPXParsedSegment(points: [GPXParsedPoint(latitude: 37.0, longitude: -122.0)])
            ])
        ])
        XCTAssertThrowsError(try validator.validate(document: doc, policy: .default)) { error in
            XCTAssertEqual(error as? ParsedRouteValidationFailure, .insufficientPoints(found: 1, minimumRequired: 2))
        }
    }

    func testValidateInvalidLatitudeThrowsError() {
        let doc = GPXParsedDocument(tracks: [
            GPXParsedTrack(segments: [
                GPXParsedSegment(points: [
                    GPXParsedPoint(latitude: 37.0, longitude: -122.0),
                    GPXParsedPoint(latitude: 95.0, longitude: -122.0)
                ])
            ])
        ])
        XCTAssertThrowsError(try validator.validate(document: doc, policy: .default)) { error in
            guard case .invalidCoordinate(let lat, _, _) = (error as? ParsedRouteValidationFailure) else {
                XCTFail("Expected invalidCoordinate failure")
                return
            }
            XCTAssertEqual(lat, 95.0)
        }
    }

    func testValidateValidDocumentSucceeds() {
        let doc = GPXParsedDocument(tracks: [
            GPXParsedTrack(segments: [
                GPXParsedSegment(points: [
                    GPXParsedPoint(latitude: 37.0, longitude: -122.0),
                    GPXParsedPoint(latitude: 37.1, longitude: -122.1)
                ])
            ])
        ])
        XCTAssertNoThrow(try validator.validate(document: doc, policy: .default))
    }
}
