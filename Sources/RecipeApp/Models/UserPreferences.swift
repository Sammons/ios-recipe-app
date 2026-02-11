import Foundation
import SwiftData

@Model
final class UserPreferences {
    var defaultMealSlots: [String]
    var shoppingLookaheadDays: Int
    var breakfastTime: Date
    var lunchTime: Date
    var dinnerTime: Date

    init(
        defaultMealSlots: [String] = MealSlot.allSlots,
        shoppingLookaheadDays: Int = 7,
        breakfastTime: Date = UserPreferences.defaultTime(hour: 8),
        lunchTime: Date = UserPreferences.defaultTime(hour: 12),
        dinnerTime: Date = UserPreferences.defaultTime(hour: 18)
    ) {
        self.defaultMealSlots = defaultMealSlots
        self.shoppingLookaheadDays = shoppingLookaheadDays
        self.breakfastTime = breakfastTime
        self.lunchTime = lunchTime
        self.dinnerTime = dinnerTime
    }

    static func defaultTime(hour: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
