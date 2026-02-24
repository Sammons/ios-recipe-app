import Foundation

enum AppFlags {
    static let isUITest = ProcessInfo.processInfo.arguments.contains("UITEST")
    static let inMemory = ProcessInfo.processInfo.arguments.contains("UITEST_INMEMORY")
    static let shouldSeed = ProcessInfo.processInfo.arguments.contains("UITEST_SEED")
    static let shouldSeedOverdueMeals = ProcessInfo.processInfo.arguments.contains("UITEST_SEED_OVERDUE_MEALS")
    static let enableMealPromptDuringUITest =
        ProcessInfo.processInfo.arguments.contains("UITEST_ENABLE_MEAL_PROMPT")
}
