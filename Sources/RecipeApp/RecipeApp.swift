import SwiftData
import SwiftUI

@main
struct RecipeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMealCompletion = false
    @State private var overdueEntries: [MealPlanEntry] = []

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showMealCompletion) {
                    MealCompletionSheet(overdueEntries: overdueEntries)
                }
        }
        .modelContainer(for: [
            Recipe.self,
            Ingredient.self,
            RecipeIngredient.self,
            MealPlanEntry.self,
            InventoryItem.self,
            ShoppingListItem.self,
            UserPreferences.self,
        ])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkOverdueMeals()
            }
        }
    }

    @MainActor
    private func checkOverdueMeals() {
        guard
            let container = try? ModelContainer(for: Recipe.self, Ingredient.self,
                RecipeIngredient.self, MealPlanEntry.self, InventoryItem.self,
                ShoppingListItem.self, UserPreferences.self)
        else { return }
        let context = container.mainContext
        let entries = MealCompletionService.overdueEntries(context: context)
        if !entries.isEmpty {
            overdueEntries = entries
            showMealCompletion = true
        }
    }
}
