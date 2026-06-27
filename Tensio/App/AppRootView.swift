import SwiftUI
import TensioCore

struct AppRootView: View {
    @State private var savedReadings = RecentReadingStore().load()

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
            ReadingEntryView(latestSavedReading: savedReadings.first) { reading in
                savedReadings = RecentReadingStore().save(reading)
            }
        case .log:
            ReadingLogView(savedReadings: savedReadings)
        case .medicines:
            placeholder(
                title: "Medicines",
                body: "Medicine tracking comes next."
            )
        case .report:
            placeholder(
                title: "Report",
                body: "Doctor-ready summaries come after persisted readings."
            )
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
}

#Preview {
    AppRootView()
}
