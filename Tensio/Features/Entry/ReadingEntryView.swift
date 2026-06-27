import SwiftUI
import TensioCore

struct ReadingEntryView: View {
    let latestSavedReading: SavedReading?
    let onSave: (BloodPressureReading) -> Void

    @State private var draft = ReadingEntryDraft()
    @State private var warningSymptomsPresent: Bool?

    private var reading: BloodPressureReading? {
        draft.makeReading()
    }

    private var guidance: ClinicalGuidance? {
        draft.guidance(
            emergencySymptomsPresent: showsSymptomsQuestion ? warningSymptomsPresent : nil
        )
    }

    private var readingCategoryTitle: String? {
        reading?.category.title
    }

    private var showsSymptomsQuestion: Bool {
        reading?.category == .severe
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleBlock
                inputBlock
                guidanceBlock

                Button("Save reading") {
                    saveReading()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 56)
                .disabled(!draft.validation.canSave)
                .accessibilityHint("Saves this manual reading on device.")

                if let latestSavedReading {
                    latestReadingCard(latestSavedReading)
                }
            }
            .padding(20)
        }
        .navigationTitle("Today")
        .onChange(of: showsSymptomsQuestion) { _, isSevere in
            if !isSevere {
                warningSymptomsPresent = nil
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's reading")
                .font(.largeTitle.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Enter values from cuff monitor. Tensio logs readings only. It does not measure blood pressure.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var inputBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReadingValueField(
                title: "Systolic",
                text: $draft.systolicText,
                error: draft.validation.systolicError
            )
            ReadingValueField(
                title: "Diastolic",
                text: $draft.diastolicText,
                error: draft.validation.diastolicError
            )
            ReadingValueField(
                title: "Pulse (optional)",
                text: $draft.pulseText,
                error: draft.validation.pulseError
            )
        }
    }

    @ViewBuilder
    private var guidanceBlock: some View {
        if let guidance, let readingCategoryTitle {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.headline)
                    Text(readingCategoryTitle)
                        .font(.title3.weight(.semibold))
                    Text(guidance.title)
                        .font(.headline)
                        .foregroundStyle(guidance.showsEmergencyWarning ? .red : .primary)
                    Text(guidance.detail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if showsSymptomsQuestion {
                    symptomQuestionBlock
                }

                Text("Next step: \(guidance.action)")
                    .font(.body.weight(.medium))
                    .foregroundStyle(guidance.showsEmergencyWarning ? .red : .primary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func latestReadingCard(_ reading: SavedReading) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest saved reading")
                .font(.headline)

            Text(reading.formattedPressure)
                .font(.title2.monospacedDigit().weight(.semibold))

            Text(reading.categoryTitle)
                .font(.body.weight(.medium))

            if let pulse = reading.formattedPulse {
                Text(pulse)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text(reading.recordedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func saveReading() {
        guard let reading = draft.makeReading() else {
            return
        }

        onSave(reading)
        draft = ReadingEntryDraft()
        warningSymptomsPresent = nil
    }

    private var symptomQuestionBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Warning symptoms right now?")
                .font(.headline)

            VStack(spacing: 10) {
                symptomAnswerButton(
                    title: "No warning symptoms",
                    systemImage: "checkmark.circle",
                    isSelected: warningSymptomsPresent == false,
                    role: nil
                ) {
                    warningSymptomsPresent = false
                }

                symptomAnswerButton(
                    title: "Symptoms present",
                    systemImage: "exclamationmark.triangle",
                    isSelected: warningSymptomsPresent == true,
                    role: .destructive
                ) {
                    warningSymptomsPresent = true
                }
            }
        }
    }

    private func symptomAnswerButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        role: ButtonRole?,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: 10) {
                Image(systemName: selectedSystemImage(for: systemImage, isSelected: isSelected))
                    .imageScale(.large)

                Text(title)
                    .font(.body.weight(.semibold))

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        }
        .buttonStyle(.borderedProminent)
        .tint(role == .destructive ? .red : .teal)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func selectedSystemImage(for systemImage: String, isSelected: Bool) -> String {
        guard isSelected else {
            return systemImage
        }

        switch systemImage {
        case "exclamationmark.triangle":
            return "exclamationmark.triangle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }
}

private struct ReadingValueField: View {
    let title: String
    @Binding var text: String
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: $text)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 56)
                .accessibilityLabel(title)

            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReadingEntryView(latestSavedReading: nil) { _ in }
    }
}
