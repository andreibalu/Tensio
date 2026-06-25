import Foundation

public struct BloodPressureReading: Equatable, Sendable {
    public let systolic: Int
    public let diastolic: Int
    public let pulse: Int?
    public let recordedAt: Date

    public init(
        systolic: Int,
        diastolic: Int,
        pulse: Int? = nil,
        recordedAt: Date = .now
    ) {
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
        self.recordedAt = recordedAt
    }

    public var category: BloodPressureCategory {
        BloodPressureCategory.classify(systolic: systolic, diastolic: diastolic)
    }
}
