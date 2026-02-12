import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext

    private var prefs: UserPreferences? { preferences.first }

    var body: some View {
        NavigationStack {
            if let prefs {
                preferencesForm(prefs)
            } else {
                ProgressView()
                    .task { ensurePreferencesExist() }
            }
        }
    }

    private func ensurePreferencesExist() {
        guard preferences.isEmpty else { return }
        modelContext.insert(UserPreferences())
        try? modelContext.save()
    }

    @ViewBuilder
    private func preferencesForm(_ prefs: UserPreferences) -> some View {
        Form {
            Section {
                ForEach(MealSlot.allSlots, id: \.self) { slot in
                    Toggle(slot, isOn: Binding(
                        get: { prefs.defaultMealSlots.contains(slot) },
                        set: { enabled in
                            if enabled {
                                if !prefs.defaultMealSlots.contains(slot) {
                                    prefs.defaultMealSlots.append(slot)
                                }
                            } else {
                                prefs.defaultMealSlots.removeAll { $0 == slot }
                            }
                        }
                    ))
                }
            } header: {
                Text("Meal Slots")
            } footer: {
                Text("Turn meal slots on or off to match how you plan your day.")
            }

            Section {
                DatePicker("Breakfast", selection: Binding(
                    get: { prefs.breakfastTime },
                    set: { prefs.breakfastTime = $0 }
                ), displayedComponents: .hourAndMinute)

                DatePicker("Lunch", selection: Binding(
                    get: { prefs.lunchTime },
                    set: { prefs.lunchTime = $0 }
                ), displayedComponents: .hourAndMinute)

                DatePicker("Dinner", selection: Binding(
                    get: { prefs.dinnerTime },
                    set: { prefs.dinnerTime = $0 }
                ), displayedComponents: .hourAndMinute)
            } header: {
                Text("Meal Times")
            } footer: {
                Text("Used as suggested defaults when adding meals to the calendar.")
            }

            Section("Shopping List") {
                Stepper(
                    "Lookahead: \(prefs.shoppingLookaheadDays) days",
                    value: Binding(
                        get: { prefs.shoppingLookaheadDays },
                        set: { prefs.shoppingLookaheadDays = $0 }
                    ),
                    in: 1...30
                )
            }
        }
        .navigationTitle("Preferences")
    }
}
