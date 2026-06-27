import Foundation
import TensioCore

struct SavedReading: Codable, Equatable, Identifiable {
    let systolic: Int
    let diastolic: Int
    let pulse: Int?
    let recordedAt: Date

    var id: Date { recordedAt }

    var categoryTitle: String {
        BloodPressureCategory.classify(systolic: systolic, diastolic: diastolic).title
    }

    var formattedPressure: String {
        "\(systolic) / \(diastolic) mmHg"
    }

    var formattedPulse: String? {
        guard let pulse else {
            return nil
        }
        return "\(pulse) bpm"
    }

    init(reading: BloodPressureReading) {
        systolic = reading.systolic
        diastolic = reading.diastolic
        pulse = reading.pulse
        recordedAt = reading.recordedAt
    }
}

struct RecentReadingStore {
    private let defaults: UserDefaults
    private let storageKey: String
    private let limit: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "recent-blood-pressure-readings",
        limit: Int = 20
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.limit = limit
    }

    func load() -> [SavedReading] {
        guard
            let data = defaults.data(forKey: storageKey),
            let readings = try? JSONDecoder().decode([SavedReading].self, from: data)
        else {
            return []
        }

        return readings.sorted { $0.recordedAt > $1.recordedAt }
    }

    @discardableResult
    func save(_ reading: BloodPressureReading) -> [SavedReading] {
        var readings = load()
        readings.insert(SavedReading(reading: reading), at: 0)
        let trimmedReadings = Array(readings.prefix(limit))

        if let data = try? JSONEncoder().encode(trimmedReadings) {
            defaults.set(data, forKey: storageKey)
        }

        return trimmedReadings
    }
}
