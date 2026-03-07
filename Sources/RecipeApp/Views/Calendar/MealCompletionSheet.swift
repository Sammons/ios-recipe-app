import SwiftData
import SwiftUI

struct MealCompletionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntries: [MealPlanEntry]
    @State private var skippedDeductions: [SkippedDeduction] = []
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

                    ForEach(pendingEntries, id: \.persistentModelID) { entry in
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
                                let skipped = MealCompletionService.markCompleted(entry, context: modelContext)
                                skippedDeductions = skipped
                                removeEntry(entry)
                            } label: {
                                Label("Made", systemImage: "checkmark.circle.fill")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("meal-checkin-complete")
                            .accessibilityLabel("Mark meal completed")

                            Button {
                                MealCompletionService.markSkipped(entry, context: modelContext)
                                removeEntry(entry)
                            } label: {
                                Label("Skipped", systemImage: "xmark.circle.fill")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("meal-checkin-skip")
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
            .alert(
                "Inventory Not Updated",
                isPresented: Binding(
                    get: { !skippedDeductions.isEmpty },
                    set: { if !$0 { skippedDeductions = [] } }
                )
            ) {
                Button("OK", role: .cancel) { skippedDeductions = [] }
            } message: {
                let names = skippedDeductions.map(\.ingredientName).joined(separator: ", ")
                Text("Could not deduct \(names) from inventory due to incompatible units. Update your inventory manually.")
            }
        }
    }

    private func removeEntry(_ entry: MealPlanEntry) {
        pendingEntries.removeAll { candidate in
            candidate.persistentModelID == entry.persistentModelID
        }

        if pendingEntries.isEmpty {
            onFinished?()
        }
    }
}
