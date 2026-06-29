import SwiftData
import XCTest
@testable import Tensio
import TensioCore

@MainActor
final class PersistenceTests: XCTestCase {
    func testReadingRecordsFetchNewestFirst() throws {
        let container = try TensioModelContainer.make(inMemory: true)
        let context = container.mainContext

        context.insert(
            BPReadingRecord(
                reading: BloodPressureReading(
                    systolic: 128,
                    diastolic: 78,
                    pulse: 63,
                    recordedAt: Date(timeIntervalSince1970: 100)
                )
            )
        )
        context.insert(
            BPReadingRecord(
                reading: BloodPressureReading(
                    systolic: 142,
                    diastolic: 91,
                    pulse: 74,
                    recordedAt: Date(timeIntervalSince1970: 200)
                )
            )
        )
        try context.save()

        let records = try context.fetch(BPReadingRecord.fetchDescriptor(limit: 10))

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.map(\.systolic), [142, 128])
        XCTAssertEqual(records.map(\.savedReading.categoryTitle), ["High blood pressure stage 2", "Elevated"])
        XCTAssertEqual(records.first?.savedReading.formattedPulse, "74 bpm")
    }

    func testSwiftDataReadingSaverPersistsRecord() throws {
        let container = try TensioModelContainer.make(inMemory: true)
        let context = container.mainContext
        let saver = SwiftDataReadingSaver()

        try saver.save(
            BloodPressureReading(
                systolic: 118,
                diastolic: 76,
                pulse: 60,
                recordedAt: Date(timeIntervalSince1970: 300)
            ),
            in: context
        )

        let records = try context.fetch(BPReadingRecord.fetchDescriptor(limit: 10))

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.savedReading.formattedPressure, "118 / 76 mmHg")
        XCTAssertEqual(records.first?.savedReading.formattedPulse, "60 bpm")
    }

    func testReportSummaryUsesStoredReadings() throws {
        let container = try TensioModelContainer.make(inMemory: true)
        let context = container.mainContext

        context.insert(
            BPReadingRecord(
                reading: BloodPressureReading(
                    systolic: 126,
                    diastolic: 78,
                    pulse: 66,
                    recordedAt: Date(timeIntervalSince1970: 100)
                )
            )
        )
        context.insert(
            BPReadingRecord(
                reading: BloodPressureReading(
                    systolic: 144,
                    diastolic: 92,
                    pulse: 74,
                    recordedAt: Date(timeIntervalSince1970: 200)
                )
            )
        )
        try context.save()

        let records = try context.fetch(BPReadingRecord.fetchDescriptor(limit: 10))
        let summary = ReportSummary.make(
            readings: records.map(\.coreReading),
            now: Date(timeIntervalSince1970: 400)
        )

        XCTAssertEqual(summary.readingCount, 2)
        XCTAssertEqual(summary.averageSystolic, 135)
        XCTAssertEqual(summary.averageDiastolic, 85)
        XCTAssertEqual(summary.highestCategory, .stage2)
        XCTAssertEqual(summary.latestReading?.systolic, 144)
        XCTAssertEqual(summary.stage2OrHigherCount, 1)
    }
}
