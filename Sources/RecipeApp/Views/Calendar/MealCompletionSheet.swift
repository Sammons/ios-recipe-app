import SwiftData
import SwiftUI

struct MealCompletionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntries: [MealPlanEntry]
    var onFinished: (() -> Void)?

    init(overdueEntries: [MealPlanEntry], onFinished: (() -> Void)? = nil) {
        _pendingEntries = State(initialValue: overdueEntries)
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            List {
                if pendingEntries.isEmpty {
                    ContentUnavailableView(
                        "No overdue meals",
                        systemImage: "checkmark.circle",
                        description: Text("You're all caught up.")
                    )
                    .accessibilityIdentifier("meal-checkin-empty")
                } else {
                    Section {
                        Text("You have meals that haven't been marked. Did you make them?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(Array(pendingEntries.enumerated()), id: \.offset) { index, entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.recipe?.title ?? "Unknown")
                                    .font(.headline)
                                Text("\(entry.mealSlot) · \(DateHelpers.shortDateString(entry.date))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                MealCompletionService.markCompleted(entry, context: modelContext)
                                removeEntry(entry)
                            } label: {
                                Label("Made", systemImage: "checkmark.circle.fill")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("meal-checkin-complete-\(index)")
                            .accessibilityLabel("Mark meal completed")

                            Button {
                                MealCompletionService.markSkipped(entry, context: modelContext)
                                removeEntry(entry)
                            } label: {
                                Label("Skipped", systemImage: "xmark.circle.fill")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("meal-checkin-skip-\(index)")
                            .accessibilityLabel("Mark meal skipped")
                        }
                    }
                }
            }
            .navigationTitle("Meal Check-in")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("meal-checkin-done")
            }
        }
    }

    private func removeEntry(_ entry: MealPlanEntry) {
        pendingEntries.removeAll { candidate in
            candidate.persistentModelID == entry.persistentModelID
        }

        if pendingEntries.isEmpty {
            DispatchQueue.main.async {
                onFinished?()
                dismiss()
            }
        }
    }
}
