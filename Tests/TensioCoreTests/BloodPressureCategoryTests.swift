import XCTest
@testable import TensioCore

final class BloodPressureCategoryTests: XCTestCase {
    func testClassifiesElevatedReadingFromSystolicRange() {
        let category = BloodPressureCategory.classify(systolic: 124, diastolic: 78)

        XCTAssertEqual(category, .elevated)
    }

    func testClassifiesStageOneWhenDiastolicInRange() {
        let category = BloodPressureCategory.classify(systolic: 118, diastolic: 84)

        XCTAssertEqual(category, .stage1)
    }

    func testClassifiesSevereReadingAboveCrisisThreshold() {
        let category = BloodPressureCategory.classify(systolic: 182, diastolic: 121)

        XCTAssertEqual(category, .severe)
    }

    func testSevereGuidancePromptsRetakeAndSymptomCheckBeforeSymptomsAnswered() {
        let reading = BloodPressureReading(systolic: 186, diastolic: 121)

        let guidance = ClinicalGuidance.guidance(for: reading)

        XCTAssertEqual(guidance.title, "Take another reading")
        XCTAssertTrue(guidance.shouldPromptForEmergencySymptoms)
        XCTAssertTrue(guidance.shouldSuggestRetake)
        XCTAssertFalse(guidance.showsEmergencyWarning)
        XCTAssertEqual(guidance.action, "Wait at least 1 minute and retake")
    }

    func testSevereGuidanceEscalatesWhenEmergencySymptomsPresent() {
        let reading = BloodPressureReading(systolic: 184, diastolic: 122)

        let guidance = ClinicalGuidance.guidance(for: reading, emergencySymptomsPresent: true)

        XCTAssertTrue(guidance.showsEmergencyWarning)
        XCTAssertEqual(guidance.action, "Call emergency services")
        XCTAssertFalse(guidance.shouldSuggestRetake)
    }
}
