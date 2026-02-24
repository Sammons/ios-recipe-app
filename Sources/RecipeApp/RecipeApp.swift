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

        do {
            self.sharedContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            print("ERROR: Failed to create ModelContainer: \(error.localizedDescription)")
            print("Falling back to in-memory storage")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                self.sharedContainer = try ModelContainer(for: schema, configurations: fallbackConfig)
            } catch {
                fatalError("ERROR: Failed to create fallback in-memory ModelContainer: \(error.localizedDescription)")
            }
        }

        let context = sharedContainer.mainContext
        if AppFlags.shouldSeedOverdueMeals {
            SeedData.seedOverdueMealCheckinScenario(context: context)
        } else if AppFlags.shouldSeed {
            SeedData.seedIfEmpty(context: context)
        }
        if AppFlags.shouldSeed || AppFlags.shouldSeedOverdueMeals {
            IngredientCatalogSeeder.seedMissing(context: context)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(
                    isPresented: mealCompletionPresentationBinding,
                    onDismiss: {
                        overdueEntries = []
                        showMealCompletion = false
                    }
                ) {
                    MealCompletionSheet(
                        overdueEntries: overdueEntries,
                        onFinished: {
                            overdueEntries = []
                            showMealCompletion = false
                        }
                    )
                }
        }
        .modelContainer(sharedContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && (!AppFlags.isUITest || AppFlags.enableMealPromptDuringUITest) {
                checkOverdueMeals()
            }
        }
    }

    private var mealCompletionPresentationBinding: Binding<Bool> {
        Binding(
            get: { showMealCompletion && !overdueEntries.isEmpty },
            set: { newValue in
                showMealCompletion = newValue
                if !newValue {
                    overdueEntries = []
                }
            }
        )
    }

    @MainActor
    private func checkOverdueMeals() {
        let context = sharedContainer.mainContext
        let entries = MealCompletionService.overdueEntries(context: context)
        overdueEntries = entries
        showMealCompletion = !entries.isEmpty
    }
}
