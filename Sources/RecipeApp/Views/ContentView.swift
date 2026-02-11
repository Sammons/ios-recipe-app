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
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.rawValue, systemImage: tab.icon, value: tab) {
                    switch tab {
                    case .calendar:
                        CalendarView()
                    case .recipeBuilder:
                        RecipeBuilderView()
                    case .shoppingList:
                        ShoppingListView()
                    case .inventory:
                        InventoryView()
                    case .recipeBook:
                        RecipeBookView()
                    case .preferences:
                        PreferencesView()
                    case .help:
                        HelpView()
                    }
                }
            }
        }
    }
}
