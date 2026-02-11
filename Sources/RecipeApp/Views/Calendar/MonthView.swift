import SwiftData
import SwiftUI

struct MonthView: View {
    @Binding var selectedDate: Date
    @Query private var allEntries: [MealPlanEntry]

    private var monthStart: Date { DateHelpers.startOfMonth(selectedDate) }
    private var daysInMonth: [Date] { DateHelpers.daysInMonth(selectedDate) }

    private var leadingBlanks: Int {
        let weekday = DateHelpers.weekday(monthStart)
        return weekday - 1
    }

    private func entries(for date: Date) -> [MealPlanEntry] {
        let start = DateHelpers.startOfDay(date)
        let end = DateHelpers.endOfDay(date)
        return allEntries.filter { $0.date >= start && $0.date < end }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdayHeaders = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            monthNavigationBar

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 50)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        DayCell(
                            date: date,
                            entries: entries(for: date),
                            isSelected: DateHelpers.isSameDay(date, selectedDate),
                            isToday: DateHelpers.isToday(date)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            Spacer()
        }
    }

    private var monthNavigationBar: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(
                    byAdding: .month, value: -1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(DateHelpers.monthYearString(selectedDate))
                .font(.headline)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(
                    byAdding: .month, value: 1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }
}

struct DayCell: View {
    let date: Date
    let entries: [MealPlanEntry]
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(DateHelpers.dayNumber(date))")
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)

            HStack(spacing: 2) {
                ForEach(mealDots, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.2)
                        : isToday ? Color.accentColor.opacity(0.08) : Color.clear
                )
        )
    }

    private var mealDots: [Color] {
        let slots = Set(entries.map(\.mealSlot))
        var dots: [Color] = []
        if slots.contains(MealSlot.breakfast) { dots.append(.blue) }
        if slots.contains(MealSlot.lunch) { dots.append(.green) }
        if slots.contains(MealSlot.dinner) { dots.append(.orange) }
        if slots.contains(MealSlot.snack) { dots.append(.purple) }
        return dots
    }
}
