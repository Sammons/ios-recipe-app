import SwiftData
import SwiftUI

struct DayView: View {
    @Binding var selectedDate: Date
    @Query private var allEntries: [MealPlanEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showingRecipePicker: String?

    private var dayStart: Date { DateHelpers.startOfDay(selectedDate) }
    private var dayEnd: Date { DateHelpers.endOfDay(selectedDate) }

    private var todayEntries: [MealPlanEntry] {
        allEntries.filter { entry in
            entry.date >= dayStart && entry.date < dayEnd
        }
    }

    private func entry(for slot: String) -> MealPlanEntry? {
        todayEntries.first { $0.mealSlot == slot }
    }

    var body: some View {
        VStack(spacing: 0) {
            dateNavigationBar

            List {
                ForEach(MealSlot.allSlots, id: \.self) { slot in
                    Section(slot) {
                        if let entry = entry(for: slot) {
                            mealEntryRow(entry)
                        } else {
                            Button {
                                showingRecipePicker = slot
                            } label: {
                                Label("Tap to add", systemImage: "plus.circle.dashed")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $showingRecipePicker) { slot in
            RecipePickerView { recipe in
                addMealEntry(recipe: recipe, slot: slot)
            }
        }
    }

    private var dateNavigationBar: some View {
        HStack {
            Button {
                selectedDate = DateHelpers.addDays(-1, to: selectedDate)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            VStack {
                Text(DateHelpers.shortDateString(selectedDate))
                    .font(.headline)
                if DateHelpers.isToday(selectedDate) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }
            }

            Spacer()

            Button {
                selectedDate = DateHelpers.addDays(1, to: selectedDate)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private func mealEntryRow(_ entry: MealPlanEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.recipe?.title ?? "Unknown Recipe")
                    .font(.headline)
                    .strikethrough(entry.status == MealStatus.skipped)
                Text("\(entry.servings) serving\(entry.servings == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.status == MealStatus.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if entry.status == MealStatus.skipped {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func addMealEntry(recipe: Recipe, slot: String) {
        let entry = MealPlanEntry(
            date: dayStart,
            mealSlot: slot,
            servings: recipe.servings,
            recipe: recipe
        )
        modelContext.insert(entry)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
