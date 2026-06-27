import Foundation
import XCTest
@testable import Tensio
import TensioCore

@MainActor
final class RecentReadingStoreTests: XCTestCase {
    func testSavePersistsNewestReadingFirst() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = RecentReadingStore(defaults: defaults, storageKey: "saved-readings")
        let olderReading = BloodPressureReading(
            systolic: 128,
            diastolic: 78,
            pulse: 63,
            recordedAt: Date(timeIntervalSince1970: 100)
        )
        let newerReading = BloodPressureReading(
            systolic: 142,
            diastolic: 91,
            pulse: 74,
            recordedAt: Date(timeIntervalSince1970: 200)
        )

        store.save(olderReading)
        let savedReadings = store.save(newerReading)

        XCTAssertEqual(savedReadings.count, 2)
        XCTAssertEqual(savedReadings.first?.systolic, 142)
        XCTAssertEqual(store.load().map(\.diastolic), [91, 78])
    }
}
