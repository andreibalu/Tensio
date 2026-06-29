import Foundation
import SwiftData
import TensioCore

struct SavedReading: Equatable, Identifiable {
    let id: UUID
    let systolic: Int
    let diastolic: Int
    let pulse: Int?
    let recordedAt: Date

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
}

@Model
final class BPReadingRecord {
    var id: UUID
    var systolic: Int
    var diastolic: Int
    var pulse: Int?
    var recordedAt: Date

    init(
        id: UUID = UUID(),
        systolic: Int,
        diastolic: Int,
        pulse: Int?,
        recordedAt: Date
    ) {
        self.id = id
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
        self.recordedAt = recordedAt
    }

    convenience init(reading: BloodPressureReading) {
        self.init(
            systolic: reading.systolic,
            diastolic: reading.diastolic,
            pulse: reading.pulse,
            recordedAt: reading.recordedAt
        )
    }

    var savedReading: SavedReading {
        SavedReading(
            id: id,
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            recordedAt: recordedAt
        )
    }

    var coreReading: BloodPressureReading {
        BloodPressureReading(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            recordedAt: recordedAt
        )
    }

    static func fetchDescriptor(limit: Int? = nil) -> FetchDescriptor<BPReadingRecord> {
        var descriptor = FetchDescriptor<BPReadingRecord>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit ?? 0
        return descriptor
    }
}
