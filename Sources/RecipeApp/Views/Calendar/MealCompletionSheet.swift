import SwiftData
import SwiftUI

struct MealCompletionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntries: [MealPlanEntry]

    init(overdueEntries: [MealPlanEntry]) {
        _pendingEntries = State(initialValue: overdueEntries)
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
                } else {
                    Section {
                        Text("You have meals that haven't been marked. Did you make them?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(pendingEntries) { entry in
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
                                Image(systemName: "checkmark.circle")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)

                            Button {
                                MealCompletionService.markSkipped(entry, context: modelContext)
                                removeEntry(entry)
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
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
            }
        }
    }

    private func removeEntry(_ entry: MealPlanEntry) {
        pendingEntries.removeAll { candidate in
            ObjectIdentifier(candidate) == ObjectIdentifier(entry)
        }

        if pendingEntries.isEmpty {
            dismiss()
        }
    }
}
