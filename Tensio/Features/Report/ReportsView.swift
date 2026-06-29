import SwiftData
import SwiftUI
import TensioCore

struct ReportsView: View {
    @Query(sort: \BPReadingRecord.recordedAt, order: .reverse) private var readingRecords: [BPReadingRecord]

    private var summary: ReportSummary {
        ReportSummary.make(readings: readingRecords.map(\.coreReading), now: .now)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleBlock

                if readingRecords.isEmpty {
                    emptyState
                } else {
                    averageCard
                    highlightsCard
                    latestReadingCard
                    safetyNoteCard
                }
            }
            .padding(20)
        }
        .navigationTitle("Report")
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doctor summary")
                .font(.largeTitle.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Review saved cuff readings before a visit. Tensio keeps this summary on device.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        reportCard {
            Text("Save a reading to build doctor summary.")
                .font(.title3.weight(.semibold))

            Text("After first saved reading, Report will show average blood pressure, latest reading, and highest category for quick visit prep.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var averageCard: some View {
        reportCard {
            Text("Average blood pressure")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(summary.formattedAveragePressure)
                .font(.system(size: 38, weight: .semibold, design: .rounded))

            Text("\(summary.readingCount) saved reading\(summary.readingCount == 1 ? "" : "s")")
                .font(.body.weight(.medium))
        }
    }

    private var highlightsCard: some View {
        reportCard {
            reportRow(
                title: "Highest category",
                value: summary.highestCategory?.title ?? "No readings"
            )
            reportRow(
                title: "Stage 2 or higher",
                value: "\(summary.stage2OrHigherCount)"
            )
            reportRow(
                title: "Summary updated",
                value: summary.generatedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    private var latestReadingCard: some View {
        reportCard {
            Text("Latest reading")
                .font(.headline)

            if let latestReading = summary.latestReading {
                Text(latestReading.formattedPressure)
                    .font(.title2.monospacedDigit().weight(.semibold))

                Text(latestReading.category.title)
                    .font(.body.weight(.medium))

                if let pulse = latestReading.formattedPulse {
                    Text(pulse)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Text(latestReading.recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var safetyNoteCard: some View {
        reportCard {
            Text("Visit note")
                .font(.headline)

            Text("Tensio logs readings from an external blood pressure monitor. It does not diagnose conditions or recommend medication changes.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func reportRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private func reportCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension ReportSummary {
    var formattedAveragePressure: String {
        guard let averageSystolic, let averageDiastolic else {
            return "No readings yet"
        }

        return "\(averageSystolic) / \(averageDiastolic) mmHg"
    }
}

private extension BloodPressureReading {
    var formattedPressure: String {
        "\(systolic) / \(diastolic) mmHg"
    }

    var formattedPulse: String? {
        guard let pulse else {
            return nil
        }

        return "\(pulse) bpm"
    }
}
