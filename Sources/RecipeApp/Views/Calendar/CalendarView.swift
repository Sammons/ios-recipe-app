import SwiftData
import SwiftUI

enum CalendarMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarMode = .day

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $calendarMode) {
                    ForEach(CalendarMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch calendarMode {
                case .day:
                    DayView(selectedDate: $selectedDate)
                case .week:
                    WeekView(selectedDate: $selectedDate)
                case .month:
                    MonthView(selectedDate: $selectedDate)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Today") {
                        selectedDate = Date()
                    }
                }
            }
        }
    }
}
