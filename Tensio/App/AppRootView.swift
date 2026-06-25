import SwiftUI
import TensioCore

struct AppRootView: View {
    var body: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(tab.title)
                            .font(.largeTitle.weight(.semibold))

                        Text(statusCopy(for: tab))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(24)
                    .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
    }

    private func statusCopy(for tab: MainTab) -> String {
        switch tab {
        case .today:
            "Ready for fast manual blood pressure entry."
        case .log:
            "Core category engine loaded: \(BloodPressureCategory.normal.title)."
        case .medicines:
            "Medicine tracking comes next."
        case .report:
            "Doctor-ready summaries come after persisted readings."
        case .settings:
            "Local-first, no-account defaults."
        }
    }
}

#Preview {
    AppRootView()
}
