import SwiftData
import SwiftUI

struct ReadingLogView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \BPReadingRecord.recordedAt, order: .reverse) private var readingRecords: [BPReadingRecord]

    private var savedReadings: [SavedReading] {
        readingRecords.map(\.savedReading)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if savedReadings.isEmpty {
                    logCard {
                        Text("Saved readings will appear here after first entry.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Saved readings")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(savedReadings) { reading in
                        logCard {
                            VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 10 : 6) {
                                Text(reading.formattedPressure)
                                    .font(.title3.monospacedDigit().weight(.semibold))

                                Text(reading.categoryTitle)
                                    .font(.body.weight(.medium))

                                Text(reading.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Log")
    }
}

private extension ReadingLogView {
    func logCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
