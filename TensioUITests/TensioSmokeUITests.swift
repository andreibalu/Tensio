import XCTest

@MainActor
final class TensioSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsTodayTab() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Today's reading"].exists)
        XCTAssertFalse(app.buttons["Save reading"].isEnabled)
    }

    func testSavingValidReadingShowsSavedReadingCard() throws {
        let app = XCUIApplication()
        app.launch()

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        systolicField.tap()
        systolicField.typeText("128")
        diastolicField.tap()
        diastolicField.typeText("79")

        let saveButton = app.buttons["Save reading"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Latest saved reading"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["128 / 79 mmHg"].exists)
    }

    func testSevereReadingPromptsSymptomQuestionBeforeAnswer() throws {
        let app = XCUIApplication()
        app.launch()

        let systolicField = app.textFields["Systolic"]
        let diastolicField = app.textFields["Diastolic"]

        XCTAssertTrue(systolicField.waitForExistence(timeout: 5))
        systolicField.tap()
        systolicField.typeText("184")
        diastolicField.tap()
        diastolicField.typeText("121")

        XCTAssertTrue(app.staticTexts["Warning symptoms right now?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'chest pain'")).firstMatch.exists)
    }
}
