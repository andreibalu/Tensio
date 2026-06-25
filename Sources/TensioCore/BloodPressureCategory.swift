public enum BloodPressureCategory: String, CaseIterable, Sendable {
    case normal
    case elevated
    case stage1
    case stage2
    case severe

    public static func classify(systolic: Int, diastolic: Int) -> BloodPressureCategory {
        if systolic > 180 || diastolic > 120 {
            return .severe
        }

        if systolic >= 140 || diastolic >= 90 {
            return .stage2
        }

        if systolic >= 130 || diastolic >= 80 {
            return .stage1
        }

        if (120...129).contains(systolic) && diastolic < 80 {
            return .elevated
        }

        return .normal
    }

    public var title: String {
        switch self {
        case .normal:
            "Normal"
        case .elevated:
            "Elevated"
        case .stage1:
            "High blood pressure stage 1"
        case .stage2:
            "High blood pressure stage 2"
        case .severe:
            "Severe high blood pressure"
        }
    }
}
