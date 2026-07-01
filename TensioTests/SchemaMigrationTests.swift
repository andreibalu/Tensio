import Foundation
import SwiftData
import XCTest
@testable import Tensio
import TensioCore

@MainActor
final class SchemaMigrationTests: XCTestCase {
    func testAddingMonitoringSessionSchemaPreservesExistingReadings() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("tensio-schema-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let storeURL = storeDirectory.appendingPathComponent("Tensio.store")
        let readingDate = Date(timeIntervalSince1970: 1_800_000_000)

        try createLegacyReadingStore(at: storeURL, readingDate: readingDate)

        let currentSchema = Schema([
            BPReadingRecord.self,
            MonitoringSessionRecord.self
        ])
        let currentConfiguration = ModelConfiguration(
            "Tensio",
            schema: currentSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let currentContainer = try ModelContainer(
            for: currentSchema,
            configurations: [currentConfiguration]
        )
        let currentContext = currentContainer.mainContext

        let migratedReadings = try currentContext.fetch(BPReadingRecord.fetchDescriptor())
        XCTAssertEqual(migratedReadings.count, 1)
        XCTAssertEqual(migratedReadings.first?.systolic, 132)
        XCTAssertEqual(migratedReadings.first?.diastolic, 84)
        XCTAssertEqual(migratedReadings.first?.recordedAt, readingDate)

        currentContext.insert(
            MonitoringSessionRecord(
                startedAt: readingDate,
                timeZoneIdentifier: "Europe/Bucharest"
            )
        )
        try currentContext.save()

        XCTAssertEqual(
            try currentContext.fetch(MonitoringSessionRecord.fetchDescriptor()).count,
            1
        )
    }

    private func createLegacyReadingStore(at storeURL: URL, readingDate: Date) throws {
        let legacySchema = Schema([BPReadingRecord.self])
        let legacyConfiguration = ModelConfiguration(
            "Tensio",
            schema: legacySchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let legacyContainer = try ModelContainer(
            for: legacySchema,
            configurations: [legacyConfiguration]
        )
        let legacyContext = legacyContainer.mainContext
        legacyContext.insert(
            BPReadingRecord(
                reading: BloodPressureReading(
                    systolic: 132,
                    diastolic: 84,
                    pulse: 68,
                    recordedAt: readingDate
                )
            )
        )
        try legacyContext.save()
    }
}
