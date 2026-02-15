import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable {
    case calendar = "Calendar"
    case recipeBook = "Recipe Book"
    case shoppingList = "Shopping List"
    case inventory = "Inventory"
    case recipeBuilder = "Recipe Builder"
    case preferences = "Preferences"
    case help = "Help"

    var icon: String {
        switch self {
        case .calendar: "calendar"
        case .recipeBook: "book"
        case .shoppingList: "cart"
        case .inventory: "refrigerator"
        case .recipeBuilder: "hammer"
        case .preferences: "gear"
        case .help: "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .calendar
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tag(AppTab.calendar)
                .tabItem { Label(AppTab.calendar.rawValue, systemImage: AppTab.calendar.icon) }

            RecipeBookView()
                .tag(AppTab.recipeBook)
                .tabItem { Label(AppTab.recipeBook.rawValue, systemImage: AppTab.recipeBook.icon) }

            ShoppingListView()
                .tag(AppTab.shoppingList)
                .tabItem { Label(AppTab.shoppingList.rawValue, systemImage: AppTab.shoppingList.icon) }

            InventoryView()
                .tag(AppTab.inventory)
                .tabItem { Label(AppTab.inventory.rawValue, systemImage: AppTab.inventory.icon) }

            RecipeBuilderView()
                .tag(AppTab.recipeBuilder)
                .tabItem { Label(AppTab.recipeBuilder.rawValue, systemImage: AppTab.recipeBuilder.icon) }

            PreferencesView()
                .tag(AppTab.preferences)
                .tabItem { Label(AppTab.preferences.rawValue, systemImage: AppTab.preferences.icon) }

            HelpView()
                .tag(AppTab.help)
                .tabItem { Label(AppTab.help.rawValue, systemImage: AppTab.help.icon) }
        }
        .onAppear {
            if !didSeed && AppFlags.shouldSeed {
                SeedData.seedIfEmpty(context: modelContext)
                didSeed = true
            }
        }
    }
}
