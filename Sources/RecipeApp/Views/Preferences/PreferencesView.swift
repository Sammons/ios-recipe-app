import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    @State private var didEnsurePrefs = false

    private var prefs: UserPreferences? {
        preferences.first
    }

    var body: some View {
        NavigationStack {
            Form {
                if let prefs {
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
            }
            .navigationTitle("Preferences")
            .onAppear {
                ensurePreferences()
            }
        }
    }

    private func ensurePreferences() {
        guard !didEnsurePrefs else { return }
        didEnsurePrefs = true
        if preferences.isEmpty {
            modelContext.insert(UserPreferences())
            try? modelContext.save()
        }
    }
}
