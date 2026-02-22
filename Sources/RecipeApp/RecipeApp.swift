import SwiftData
import SwiftUI

@main
struct RecipeApp: App {
    let sharedContainer: ModelContainer

    @Environment(\.scenePhase) private var scenePhase
    @State private var showMealCompletion = false
    @State private var overdueEntries: [MealPlanEntry] = []

    init() {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            RecipeIngredient.self,
            MealPlanEntry.self,
            InventoryItem.self,
            ShoppingListItem.self,
            UserPreferences.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: AppFlags.inMemory)
        // swiftlint:disable:next force_try
        self.sharedContainer = try! ModelContainer(for: schema, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(
                    isPresented: $showMealCompletion,
                    onDismiss: { overdueEntries = [] }
                ) {
                    MealCompletionSheet(overdueEntries: overdueEntries)
                }
        }
        .modelContainer(sharedContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !AppFlags.isUITest {
                checkOverdueMeals()
            }
        }
    }

    @MainActor
    private func checkOverdueMeals() {
        let context = sharedContainer.mainContext
        let entries = MealCompletionService.overdueEntries(context: context)
        overdueEntries = entries
        showMealCompletion = !entries.isEmpty
    }
}
