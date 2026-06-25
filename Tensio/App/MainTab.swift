import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case today
    case log
    case medicines
    case report
    case settings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .today:
            "Today"
        case .log:
            "Log"
        case .medicines:
            "Medicines"
        case .report:
            "Report"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "heart.text.square"
        case .log:
            "list.bullet.clipboard"
        case .medicines:
            "pills"
        case .report:
            "doc.text"
        case .settings:
            "gearshape"
        }
    }
}
