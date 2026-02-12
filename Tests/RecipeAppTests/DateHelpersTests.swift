import Testing
import Foundation
@testable import RecipeApp

@Suite("DateHelpers")
struct DateHelpersTests {
    @Test func startOfDayZeroesTimeComponents() {
        let now = Date()
        let start = DateHelpers.startOfDay(now)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func endOfDayIsNextDayMidnight() {
        let now = Date()
        let end = DateHelpers.endOfDay(now)
        let start = DateHelpers.startOfDay(now)
        let expected = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        #expect(end == expected)
    }

    @Test func addDaysPositive() {
        let today = DateHelpers.startOfDay(Date())
        let result = DateHelpers.addDays(3, to: today)
        let diff = Calendar.current.dateComponents([.day], from: today, to: result)
        #expect(diff.day == 3)
    }

    @Test func addDaysNegative() {
        let today = DateHelpers.startOfDay(Date())
        let result = DateHelpers.addDays(-2, to: today)
        let diff = Calendar.current.dateComponents([.day], from: result, to: today)
        #expect(diff.day == 2)
    }

    @Test func isSameDayPositive() {
        // Use noon to avoid crossing midnight when adding hours
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 12
        let noon = Calendar.current.date(from: components)!
        let afternoon = Calendar.current.date(byAdding: .hour, value: 3, to: noon)!
        #expect(DateHelpers.isSameDay(noon, afternoon))
    }

    @Test func isSameDayNegative() {
        let today = DateHelpers.startOfDay(Date())
        let tomorrow = DateHelpers.addDays(1, to: today)
        #expect(!DateHelpers.isSameDay(today, tomorrow))
    }

    @Test func daysInMonthReturnsCorrectCount() {
        // Feb 2024: 29 days (leap year)
        let feb2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        #expect(DateHelpers.daysInMonth(feb2024).count == 29)

        // Jan: 31 days
        let jan = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        #expect(DateHelpers.daysInMonth(jan).count == 31)

        // April: 30 days
        let apr = Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 1))!
        #expect(DateHelpers.daysInMonth(apr).count == 30)

        // Feb 2023: 28 days (non-leap)
        let feb2023 = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 1))!
        #expect(DateHelpers.daysInMonth(feb2023).count == 28)
    }

    @Test func startOfWeekIsBeforeOrEqualToDate() {
        let now = Date()
        let weekStart = DateHelpers.startOfWeek(now)
        #expect(weekStart <= now)
        let diff = Calendar.current.dateComponents([.day], from: weekStart, to: now)
        #expect(diff.day! < 7)
    }

    @Test func startOfMonthIsFirstDay() {
        let now = Date()
        let monthStart = DateHelpers.startOfMonth(now)
        let day = Calendar.current.component(.day, from: monthStart)
        #expect(day == 1)
    }
}
