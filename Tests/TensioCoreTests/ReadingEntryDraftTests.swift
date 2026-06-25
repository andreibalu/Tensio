import Foundation
import XCTest
@testable import TensioCore

final class ReadingEntryDraftTests: XCTestCase {
    func testValidationRequiresBothBloodPressureFields() {
        let draft = ReadingEntryDraft(systolicText: "132", diastolicText: "")

        XCTAssertFalse(draft.validation.canSave)
        XCTAssertEqual(draft.validation.diastolicError, "Enter diastolic pressure.")
        XCTAssertNil(draft.preview)
    }

    func testValidationRejectsImpossibleRanges() {
        let draft = ReadingEntryDraft(systolicText: "260", diastolicText: "82", pulseText: "25")

        XCTAssertFalse(draft.validation.canSave)
        XCTAssertEqual(draft.validation.systolicError, "Use value between 70 and 250.")
        XCTAssertEqual(draft.validation.pulseError, "Use pulse between 30 and 220.")
    }

    func testValidationRejectsReversedBloodPressureValues() {
        let draft = ReadingEntryDraft(systolicText: "78", diastolicText: "92")

        XCTAssertFalse(draft.validation.canSave)
        XCTAssertEqual(draft.validation.diastolicError, "Diastolic should stay below systolic.")
    }

    func testPreviewUsesClinicalGuidanceForValidReading() {
        let draft = ReadingEntryDraft(systolicText: "184", diastolicText: "121", pulseText: "88")

        XCTAssertTrue(draft.validation.canSave)
        XCTAssertEqual(draft.preview?.categoryTitle, "Severe high blood pressure")
        XCTAssertEqual(draft.preview?.guidanceTitle, "Take another reading")
        XCTAssertEqual(draft.preview?.actionTitle, "Wait at least 1 minute and retake")
    }

    func testMakeReadingBuildsSavableReadingFromValidatedFields() {
        let recordedAt = Date(timeIntervalSince1970: 1234)
        let draft = ReadingEntryDraft(systolicText: "128", diastolicText: "79", pulseText: "64")

        let reading = draft.makeReading(recordedAt: recordedAt)

        XCTAssertEqual(
            reading,
            BloodPressureReading(systolic: 128, diastolic: 79, pulse: 64, recordedAt: recordedAt)
        )
    }
}
