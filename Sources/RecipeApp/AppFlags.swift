import Foundation

enum AppFlags {
    static let isUITest = ProcessInfo.processInfo.arguments.contains("UITEST")
    static let inMemory = ProcessInfo.processInfo.arguments.contains("UITEST_INMEMORY")
    static let shouldSeed = ProcessInfo.processInfo.arguments.contains("UITEST_SEED")
}
