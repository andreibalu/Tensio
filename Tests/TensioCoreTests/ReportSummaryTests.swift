import Foundation
import XCTest
@testable import TensioCore

final class ReportSummaryTests: XCTestCase {
    func testSummaryUsesAverageHighestCategoryAndLatestReading() {
        let readings = [
            BloodPressureReading(
                systolic: 118,
                diastolic: 76,
                pulse: 62,
                recordedAt: Date(timeIntervalSince1970: 100)
            ),
            BloodPressureReading(
                systolic: 164,
                diastolic: 98,
                pulse: 74,
                recordedAt: Date(timeIntervalSince1970: 300)
            ),
            BloodPressureReading(
                systolic: 134,
                diastolic: 84,
                pulse: 70,
                recordedAt: Date(timeIntervalSince1970: 200)
            )
        ]

        let summary = ReportSummary.make(
            readings: readings,
            now: Date(timeIntervalSince1970: 400)
        )

        XCTAssertEqual(summary.generatedAt, Date(timeIntervalSince1970: 400))
        XCTAssertEqual(summary.readingCount, 3)
        XCTAssertEqual(summary.averageSystolic, 138)
        XCTAssertEqual(summary.averageDiastolic, 86)
        XCTAssertEqual(summary.highestCategory, .stage2)
        XCTAssertEqual(summary.latestReading?.systolic, 164)
        XCTAssertEqual(summary.latestReading?.diastolic, 98)
        XCTAssertEqual(summary.stage2OrHigherCount, 1)
    }

    func testSummaryHandlesNoReadings() {
        let summary = ReportSummary.make(readings: [], now: .distantFuture)

        XCTAssertEqual(summary.readingCount, 0)
        XCTAssertNil(summary.averageSystolic)
        XCTAssertNil(summary.averageDiastolic)
        XCTAssertNil(summary.highestCategory)
        XCTAssertNil(summary.latestReading)
        XCTAssertEqual(summary.stage2OrHigherCount, 0)
    }
}
