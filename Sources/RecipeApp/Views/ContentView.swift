import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable {
    case calendar = "Calendar"
    case recipeBuilder = "Recipe Builder"
    case shoppingList = "Shopping List"
    case inventory = "Inventory"
    case recipeBook = "Recipe Book"
    case preferences = "Preferences"
    case help = "Help"

    var icon: String {
        switch self {
        case .calendar: "calendar"
        case .recipeBuilder: "hammer"
        case .shoppingList: "cart"
        case .inventory: "refrigerator"
        case .recipeBook: "book"
        case .preferences: "gear"
        case .help: "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .calendar

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tag(AppTab.calendar)
                .tabItem { Label(AppTab.calendar.rawValue, systemImage: AppTab.calendar.icon) }

            RecipeBuilderView()
                .tag(AppTab.recipeBuilder)
                .tabItem { Label(AppTab.recipeBuilder.rawValue, systemImage: AppTab.recipeBuilder.icon) }

            ShoppingListView()
                .tag(AppTab.shoppingList)
                .tabItem { Label(AppTab.shoppingList.rawValue, systemImage: AppTab.shoppingList.icon) }

            InventoryView()
                .tag(AppTab.inventory)
                .tabItem { Label(AppTab.inventory.rawValue, systemImage: AppTab.inventory.icon) }

            RecipeBookView()
                .tag(AppTab.recipeBook)
                .tabItem { Label(AppTab.recipeBook.rawValue, systemImage: AppTab.recipeBook.icon) }

            PreferencesView()
                .tag(AppTab.preferences)
                .tabItem { Label(AppTab.preferences.rawValue, systemImage: AppTab.preferences.icon) }

            HelpView()
                .tag(AppTab.help)
                .tabItem { Label(AppTab.help.rawValue, systemImage: AppTab.help.icon) }
        }
    }
}
