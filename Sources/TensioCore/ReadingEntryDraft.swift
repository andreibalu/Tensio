import Foundation

public struct ReadingEntryDraft: Equatable, Sendable {
    public var systolicText: String
    public var diastolicText: String
    public var pulseText: String

    public init(
        systolicText: String = "",
        diastolicText: String = "",
        pulseText: String = ""
    ) {
        self.systolicText = systolicText
        self.diastolicText = diastolicText
        self.pulseText = pulseText
    }

    public var validation: ReadingEntryValidation {
        let systolicResult = Self.validatePressure(
            systolicText,
            emptyMessage: "Enter systolic pressure.",
            rangeMessage: "Use value between 70 and 250.",
            validRange: 70...250
        )
        let diastolicResult = Self.validatePressure(
            diastolicText,
            emptyMessage: "Enter diastolic pressure.",
            rangeMessage: "Use value between 40 and 150.",
            validRange: 40...150
        )
        let pulseResult = Self.validateOptionalPulse(pulseText)

        var diastolicError = diastolicResult.error
        if diastolicError == nil,
           let systolic = systolicResult.value,
           let diastolic = diastolicResult.value,
           diastolic >= systolic {
            diastolicError = "Diastolic should stay below systolic."
        }

        return ReadingEntryValidation(
            systolicError: systolicResult.error,
            diastolicError: diastolicError,
            pulseError: pulseResult.error
        )
    }

    public var preview: ReadingEntryPreview? {
        guard let reading = makeReading() else {
            return nil
        }

        let guidance = ClinicalGuidance.guidance(for: reading)
        return ReadingEntryPreview(
            category: reading.category,
            categoryTitle: reading.category.title,
            guidanceTitle: guidance.title,
            actionTitle: guidance.action
        )
    }

    public func guidance(emergencySymptomsPresent: Bool? = nil) -> ClinicalGuidance? {
        guard let reading = makeReading() else {
            return nil
        }

        return ClinicalGuidance.guidance(
            for: reading,
            emergencySymptomsPresent: emergencySymptomsPresent
        )
    }

    public func makeReading(recordedAt: Date = .now) -> BloodPressureReading? {
        guard validation.canSave else {
            return nil
        }

        guard
            let systolic = Int(systolicText.trimmingCharacters(in: .whitespacesAndNewlines)),
            let diastolic = Int(diastolicText.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }

        let pulse = Self.optionalInt(from: pulseText)
        return BloodPressureReading(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            recordedAt: recordedAt
        )
    }

    private static func validatePressure(
        _ text: String,
        emptyMessage: String,
        rangeMessage: String,
        validRange: ClosedRange<Int>
    ) -> (value: Int?, error: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (nil, emptyMessage)
        }

        guard let value = Int(trimmed) else {
            return (nil, "Use numbers only.")
        }

        guard validRange.contains(value) else {
            return (value, rangeMessage)
        }

        return (value, nil)
    }

    private static func validateOptionalPulse(_ text: String) -> (value: Int?, error: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (nil, nil)
        }

        guard let value = Int(trimmed) else {
            return (nil, "Use numbers only.")
        }

        guard (30...220).contains(value) else {
            return (value, "Use pulse between 30 and 220.")
        }

        return (value, nil)
    }

    private static func optionalInt(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return Int(trimmed)
    }
}

public struct ReadingEntryValidation: Equatable, Sendable {
    public let systolicError: String?
    public let diastolicError: String?
    public let pulseError: String?

    public init(
        systolicError: String?,
        diastolicError: String?,
        pulseError: String?
    ) {
        self.systolicError = systolicError
        self.diastolicError = diastolicError
        self.pulseError = pulseError
    }

    public var canSave: Bool {
        systolicError == nil && diastolicError == nil && pulseError == nil
    }
}

public struct ReadingEntryPreview: Equatable, Sendable {
    public let category: BloodPressureCategory
    public let categoryTitle: String
    public let guidanceTitle: String
    public let actionTitle: String

    public init(
        category: BloodPressureCategory,
        categoryTitle: String,
        guidanceTitle: String,
        actionTitle: String
    ) {
        self.category = category
        self.categoryTitle = categoryTitle
        self.guidanceTitle = guidanceTitle
        self.actionTitle = actionTitle
    }
}
