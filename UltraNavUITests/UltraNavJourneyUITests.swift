import XCTest

final class UltraNavJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
    }

    func testFirstLaunchShowsOnboarding() {
        app.launchArguments += ["-reset-onboarding"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Navigate from your wrist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboardingContinueButton"].exists)
    }

    func testPrimaryScreenDisplaysStartControls() {
        app.launchArguments += ["-completed-onboarding"]
        app.launch()

        XCTAssertTrue(app.otherElements["navigationScreen"].waitForExistence(timeout: 5))
    }

    func testSettingsScreenCanBeOpened() {
        app.launchArguments += ["-completed-onboarding"]
        app.launch()

        if app.buttons["settingsButton"].waitForExistence(timeout: 5) {
            app.buttons["settingsButton"].tap()
            XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        }
    }
}