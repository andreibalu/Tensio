import Foundation

public struct ReportSummary: Equatable, Sendable {
    public let generatedAt: Date
    public let readingCount: Int
    public let averageSystolic: Int?
    public let averageDiastolic: Int?
    public let highestCategory: BloodPressureCategory?
    public let latestReading: BloodPressureReading?
    public let stage2OrHigherCount: Int

    public init(
        generatedAt: Date,
        readingCount: Int,
        averageSystolic: Int?,
        averageDiastolic: Int?,
        highestCategory: BloodPressureCategory?,
        latestReading: BloodPressureReading?,
        stage2OrHigherCount: Int
    ) {
        self.generatedAt = generatedAt
        self.readingCount = readingCount
        self.averageSystolic = averageSystolic
        self.averageDiastolic = averageDiastolic
        self.highestCategory = highestCategory
        self.latestReading = latestReading
        self.stage2OrHigherCount = stage2OrHigherCount
    }

    public static func make(readings: [BloodPressureReading], now: Date) -> ReportSummary {
        let count = readings.count
        let averageSystolic = count == 0 ? nil : readings.map(\.systolic).reduce(0, +) / count
        let averageDiastolic = count == 0 ? nil : readings.map(\.diastolic).reduce(0, +) / count
        let latestReading = readings.max(by: { $0.recordedAt < $1.recordedAt })
        let highestCategory = readings
            .map(\.category)
            .max(by: { $0.severityRank < $1.severityRank })
        let stage2OrHigherCount = readings.filter { reading in
            reading.category.severityRank >= BloodPressureCategory.stage2.severityRank
        }.count

        return ReportSummary(
            generatedAt: now,
            readingCount: count,
            averageSystolic: averageSystolic,
            averageDiastolic: averageDiastolic,
            highestCategory: highestCategory,
            latestReading: latestReading,
            stage2OrHigherCount: stage2OrHigherCount
        )
    }
}

private extension BloodPressureCategory {
    var severityRank: Int {
        switch self {
        case .normal:
            0
        case .elevated:
            1
        case .stage1:
            2
        case .stage2:
            3
        case .severe:
            4
        }
    }
}
