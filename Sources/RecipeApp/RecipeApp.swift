import SwiftData
import SwiftUI

@main
struct RecipeApp: App {
    static let isUITest = ProcessInfo.processInfo.arguments.contains("UITEST")
    private static let inMemory = ProcessInfo.processInfo.arguments.contains("UITEST_INMEMORY")
    static let shouldSeed = ProcessInfo.processInfo.arguments.contains("UITEST_SEED")

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
        .modelContainer(
            for: [
                Recipe.self,
                Ingredient.self,
                RecipeIngredient.self,
                MealPlanEntry.self,
                InventoryItem.self,
                ShoppingListItem.self,
                UserPreferences.self,
            ],
            inMemory: Self.inMemory
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !RecipeApp.isUITest {
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
