import XCTest

@MainActor
final class TensioSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseInMemoryStore"] + arguments
        app.launch()
        return app
    }

    private func enter(_ text: String, into field: XCUIElement, app: XCUIApplication) {
        field.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))
        app.typeText(text)
    }

    func testLaunchShowsTodayTab() throws {
        let app = launchApp()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Today's reading"].exists)
        XCTAssertFalse(app.buttons["Save reading"].isEnabled)
    }

    func testSavingValidReadingShowsSavedReadingCard() throws {
        let app = launchApp()

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        enter("128", into: systolicField, app: app)
        enter("79", into: diastolicField, app: app)

        let saveButton = app.buttons["Save reading"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Latest saved reading"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["128 / 79 mmHg"].exists)
    }

    func testSevereReadingPromptsSymptomQuestionBeforeAnswer() throws {
        let app = launchApp()

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        enter("184", into: systolicField, app: app)
        enter("121", into: diastolicField, app: app)

        XCTAssertTrue(app.staticTexts["Warning symptoms right now?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'chest pain'")).firstMatch.exists)
    }

    func testSaveFailureShowsErrorAndKeepsEnteredReading() throws {
        let app = launchApp(arguments: ["UITestForceReadingSaveFailure"])

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        enter("128", into: systolicField, app: app)
        enter("79", into: diastolicField, app: app)

        let saveButton = app.buttons["Save reading"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Couldn't save reading on this iPhone right now. Check storage and try again."].waitForExistence(timeout: 5))
        XCTAssertEqual(systolicField.value as? String, "128")
        XCTAssertEqual(diastolicField.value as? String, "79")
        XCTAssertFalse(app.staticTexts["Latest saved reading"].exists)
    }

    func testReportTabShowsEmptyStateWithoutSavedReadings() throws {
        let app = launchApp()

        app.tabBars.buttons["Report"].tap()

        XCTAssertTrue(app.staticTexts["Save a reading to build doctor summary."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Report"].exists)
    }

    func testReportTabShowsSummaryAfterSavingReading() throws {
        let app = launchApp()

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        enter("128", into: systolicField, app: app)
        enter("79", into: diastolicField, app: app)
        app.buttons["Save reading"].tap()

        app.tabBars.buttons["Report"].tap()

        XCTAssertTrue(app.staticTexts["Average blood pressure"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["128 / 79 mmHg"].exists)
        XCTAssertTrue(app.staticTexts["Elevated"].exists)
    }
}
