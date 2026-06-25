public struct ClinicalGuidance: Equatable, Sendable {
    public let title: String
    public let detail: String
    public let action: String
    public let shouldPromptForEmergencySymptoms: Bool
    public let shouldSuggestRetake: Bool
    public let showsEmergencyWarning: Bool

    public init(
        title: String,
        detail: String,
        action: String,
        shouldPromptForEmergencySymptoms: Bool,
        shouldSuggestRetake: Bool,
        showsEmergencyWarning: Bool
    ) {
        self.title = title
        self.detail = detail
        self.action = action
        self.shouldPromptForEmergencySymptoms = shouldPromptForEmergencySymptoms
        self.shouldSuggestRetake = shouldSuggestRetake
        self.showsEmergencyWarning = showsEmergencyWarning
    }

    public static func guidance(
        for reading: BloodPressureReading,
        emergencySymptomsPresent: Bool? = nil
    ) -> ClinicalGuidance {
        let category = reading.category

        switch category {
        case .normal:
            return ClinicalGuidance(
                title: "Track this trend",
                detail: "Reading is in normal range today. Keep following your routine.",
                action: "Save reading",
                shouldPromptForEmergencySymptoms: false,
                shouldSuggestRetake: false,
                showsEmergencyWarning: false
            )

        case .elevated:
            return ClinicalGuidance(
                title: "Track this trend",
                detail: "Reading is elevated. Keep logging readings and discuss the pattern if it continues.",
                action: "Save reading",
                shouldPromptForEmergencySymptoms: false,
                shouldSuggestRetake: false,
                showsEmergencyWarning: false
            )

        case .stage1:
            return ClinicalGuidance(
                title: "Track this trend",
                detail: "Reading is in stage 1 range. Keep a consistent log to discuss with your clinician.",
                action: "Save reading",
                shouldPromptForEmergencySymptoms: false,
                shouldSuggestRetake: false,
                showsEmergencyWarning: false
            )

        case .stage2:
            return ClinicalGuidance(
                title: "Discuss with your clinician",
                detail: "Reading is in stage 2 range. Save it and contact your clinician if this pattern continues.",
                action: "Save reading",
                shouldPromptForEmergencySymptoms: false,
                shouldSuggestRetake: false,
                showsEmergencyWarning: false
            )

        case .severe:
            if emergencySymptomsPresent == true {
                return ClinicalGuidance(
                    title: "Emergency symptoms present",
                    detail: "Severe reading with warning symptoms needs immediate emergency care.",
                    action: "Call emergency services",
                    shouldPromptForEmergencySymptoms: false,
                    shouldSuggestRetake: false,
                    showsEmergencyWarning: true
                )
            }

            if emergencySymptomsPresent == false {
                return ClinicalGuidance(
                    title: "Take another reading",
                    detail: "Wait at least 1 minute and retake. If repeat stays this high, seek urgent medical care.",
                    action: "Wait at least 1 minute and retake",
                    shouldPromptForEmergencySymptoms: false,
                    shouldSuggestRetake: true,
                    showsEmergencyWarning: false
                )
            }

            return ClinicalGuidance(
                title: "Take another reading",
                detail: "Wait at least 1 minute, retake, and check for chest pain, trouble breathing, weakness, confusion, or vision changes.",
                action: "Wait at least 1 minute and retake",
                shouldPromptForEmergencySymptoms: true,
                shouldSuggestRetake: true,
                showsEmergencyWarning: false
            )
        }
    }
}
