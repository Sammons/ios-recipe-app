import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext

    private var prefs: UserPreferences {
        if let existing = preferences.first { return existing }
        let newPrefs = UserPreferences()
        modelContext.insert(newPrefs)
        return newPrefs
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Slots") {
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
                }

                Section("Meal Times") {
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
}
