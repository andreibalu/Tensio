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
                title: "Medicines",
                body: "Medicine tracking comes next."
            )
        case .report:
            ReportsView()
        case .settings:
            placeholder(
                title: "Settings",
                body: "Local-first, no-account defaults."
            )
        }
    }

    private func placeholder(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.largeTitle.weight(.semibold))

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
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

#Preview {
    AppRootView()
}
