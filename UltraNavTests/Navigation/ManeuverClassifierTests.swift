import XCTest
@testable import UltraNav

final class ManeuverClassifierTests: XCTestCase {
    func testAngleNormalization() {
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(0), 0)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(90), 90)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(180), 180)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(270), -90)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(360), 0)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(-90), -90)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(-270), 90)
        XCTAssertEqual(ManeuverClassifier.normalizeAngleDifference(450), 90)
    }

    func testStraightClassification() {
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 0), .continueStraight)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 15), .continueStraight)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -15), .continueStraight)
    }

    func testRightTurnClassifications() {
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 30), .slightRight)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 45), .right)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 90), .right)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 135), .sharpRight)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: 170), .uTurn)
    }

    func testLeftTurnClassifications() {
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -30), .slightLeft)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -45), .left)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -90), .left)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -135), .sharpLeft)
        XCTAssertEqual(ManeuverClassifier.classify(turnAngleDegrees: -170), .uTurn)
    }

    func testDefaultInstructions() {
        XCTAssertEqual(ManeuverClassifier.defaultInstruction(for: .left), "Turn left")
        XCTAssertEqual(ManeuverClassifier.defaultInstruction(for: .right), "Turn right")
        XCTAssertEqual(ManeuverClassifier.defaultInstruction(for: .arrive), "Arrive at destination")
        XCTAssertEqual(ManeuverClassifier.defaultInstruction(for: .uTurn), "Make a U-turn")
    }
}
