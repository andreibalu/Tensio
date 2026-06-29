import SwiftData
import SwiftUI

struct ReadingLogView: View {
    @Query(sort: \BPReadingRecord.recordedAt, order: .reverse) private var readingRecords: [BPReadingRecord]

    private var savedReadings: [SavedReading] {
        readingRecords.map(\.savedReading)
    }

    var body: some View {
        List {
            if savedReadings.isEmpty {
                Section {
                    Text("Saved readings will appear here after first entry.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Saved readings") {
                    ForEach(savedReadings) { reading in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reading.formattedPressure)
                                .font(.headline.monospacedDigit())
                            Text(reading.categoryTitle)
                                .font(.subheadline.weight(.medium))
                            Text(reading.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Log")
    }
}
