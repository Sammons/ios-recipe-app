import SwiftData
import SwiftUI

struct WeekView: View {
    @Binding var selectedDate: Date
    @Query private var allEntries: [MealPlanEntry]

    private var weekStart: Date { DateHelpers.startOfWeek(selectedDate) }

    private var weekDays: [Date] {
        (0..<7).map { DateHelpers.addDays($0, to: weekStart) }
    }

    private func mealCount(for date: Date) -> Int {
        let start = DateHelpers.startOfDay(date)
        let end = DateHelpers.endOfDay(date)
        return allEntries.filter { $0.date >= start && $0.date < end }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            weekNavigationBar

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        Button {
                            selectedDate = day
                        } label: {
                            WeekDayRow(
                                date: day,
                                mealCount: mealCount(for: day),
                                isSelected: DateHelpers.isSameDay(day, selectedDate),
                                isToday: DateHelpers.isToday(day)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }

    private var weekNavigationBar: some View {
        HStack {
            Button {
                selectedDate = DateHelpers.addDays(-7, to: selectedDate)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(weekRangeString)
                .font(.headline)

            Spacer()

            Button {
                selectedDate = DateHelpers.addDays(7, to: selectedDate)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private var weekRangeString: String {
        let start = weekDays.first ?? selectedDate
        let end = weekDays.last ?? selectedDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}

struct WeekDayRow: View {
    let date: Date
    let mealCount: Int
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(DateHelpers.shortDayName(date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(DateHelpers.dayNumber(date))")
                    .font(.title2)
                    .fontWeight(isToday ? .bold : .regular)
            }
            .frame(width: 50, alignment: .leading)

            if mealCount > 0 {
                Text("\(mealCount) meal\(mealCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.accent.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("No meals planned")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .background(isToday ? Color.accentColor.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
