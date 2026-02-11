import SwiftData
import SwiftUI

@main
struct RecipeApp: App {
    static let isUITest = ProcessInfo.processInfo.arguments.contains("UITEST")
    private static let inMemory = ProcessInfo.processInfo.arguments.contains("UITEST_INMEMORY")
    static let shouldSeed = ProcessInfo.processInfo.arguments.contains("UITEST_SEED")

    var body: some Scene {
        WindowGroup {
            RootView()
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
    }
}

private struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var showMealCompletion = false
    @State private var overdueEntries: [MealPlanEntry] = []

    var body: some View {
        ContentView()
            .sheet(isPresented: $showMealCompletion) {
                MealCompletionSheet(overdueEntries: overdueEntries)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && !RecipeApp.isUITest {
                    let entries = MealCompletionService.overdueEntries(context: modelContext)
                    if !entries.isEmpty {
                        overdueEntries = entries
                        showMealCompletion = true
                    }
                }
            }
    }
}
