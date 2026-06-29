import SwiftUI

struct AppRootView: View {
    private let readingSaver: any ReadingSaving

    init(readingSaver: (any ReadingSaving)? = nil) {
        self.readingSaver = readingSaver ?? Self.defaultReadingSaver()
    }

    var body: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    content(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for tab: MainTab) -> some View {
        switch tab {
        case .today:
            ReadingEntryView(readingSaver: readingSaver)
        case .log:
            ReadingLogView()
        case .medicines:
            placeholder(
                title: "Medicine routine",
                summary: "Medicine tracking is not in this build yet.",
                sections: [
                    PlaceholderSection(
                        title: "Planned next",
                        body: "Track medicine names, dose times, and taken or missed doses in a later update."
                    ),
                    PlaceholderSection(
                        title: "Bring now",
                        body: "For now, bring your paper list or clinician handout with this blood pressure log."
                    )
                ]
            )
        case .report:
            ReportsView()
        case .settings:
            placeholder(
                title: "Privacy and support",
                summary: "This MVP keeps readings local on this iPhone.",
                sections: [
                    PlaceholderSection(
                        title: "Current build",
                        body: "Blood pressure readings stay on this iPhone. Tensio uses no account and no analytics in MVP."
                    ),
                    PlaceholderSection(
                        title: "Coming later",
                        body: "Export, backup, and Health settings arrive in later updates."
                    )
                ]
            )
        }
    }

    private func placeholder(
        title: String,
        summary: String,
        sections: [PlaceholderSection]
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .navigationTitle(title)
    }

    private static func defaultReadingSaver() -> any ReadingSaving {
        let launchArguments = ProcessInfo.processInfo.arguments
        if launchArguments.contains("UITestForceReadingSaveFailure") {
            return FailingReadingSaver()
        }

        return SwiftDataReadingSaver()
    }
}

private struct PlaceholderSection: Identifiable {
    let id: String
    let title: String
    let body: String

    init(title: String, body: String) {
        self.id = "\(title)-\(body)"
        self.title = title
        self.body = body
    }
}

#Preview {
    AppRootView()
}
