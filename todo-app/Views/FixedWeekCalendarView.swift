import SwiftUI
import CoreData
import AppKit

struct FixedWeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    @EnvironmentObject var timeIndicatorPositioner: TimeIndicatorPositioner
    
    // Constants
    private let timeColumnWidth: CGFloat = 50
    private let allDayRowHeight: CGFloat = 24
    private let calendar = Calendar.current
    
    private var weekDays: [CalendarDay] {
        let today = visibleMonth
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: 1 - weekday, to: today)!
        var days: [CalendarDay] = []
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                days.append(CalendarDay(date: date, isCurrentMonth: calendar.isDate(date, equalTo: today, toGranularity: .month)))
            }
        }
        return days
    }
    
    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let dayColumnWidth = (availableWidth - timeColumnWidth) / 7
            
            VStack(spacing: 0) {
                // Day headers with fixed width
                HStack(spacing: 0) {
                    // Time column header
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: timeColumnWidth)
                    
                    // Day headers
                    ForEach(0..<7, id: \.self) { i in
                        let day = weekDays[i]
                        Text(formatWeekdayShort(from: day.date) + " \(calendar.component(.day, from: day.date))")
                            .font(.caption)
                            .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                            .frame(width: dayColumnWidth)
                    }
                }
                .frame(height: 25)
                .overlay(Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1), alignment: .bottom)
                
                // All-day row (fixed)
                HStack(spacing: 0) {
                    // Label
                    Text("All day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 6)
                    
                    // All-day content
                    HStack(spacing: 0) {
                        ForEach(weekDays.indices, id: \.self) { index in
                            let day = weekDays[index]
                            let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }
                            
                            ZStack {
                                // Background for today
                                Rectangle()
                                    .fill(calendar.isDateInToday(day.date) ? Color.blue.opacity(0.03) : Color.clear)
                                    .frame(width: dayColumnWidth, height: allDayRowHeight)
                                
                                // Task content
                                VStack(alignment: .leading, spacing: 0) {
                                    if !dayTasks.isEmpty {
                                        ForEach(dayTasks.prefix(1), id: \.id) { task in
                                            Text(task.title ?? "")
                                                .font(.system(size: 9))
                                                .lineLimit(1)
                                                .padding(.leading, 4)
                                        }
                                        if dayTasks.count > 1 {
                                            Text("+\(dayTasks.count-1) more")
                                                .font(.system(size: 8))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                        }
                                    }
                                }
                                .frame(width: dayColumnWidth, alignment: .leading)
                            }
                        }
                    }
                }
                .frame(height: allDayRowHeight)
                .background(Color.white)
                .overlay(Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1), alignment: .bottom)
                
                // Time grid (scrollable)
                ScrollView(.vertical, showsIndicators: true) {
                    ScrollbarWidthReader { scrollbarWidth in
                        HStack(spacing: 0) {
                            // Time labels
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(formatHour(hour))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(height: 60)
                                        .frame(width: timeColumnWidth, alignment: .trailing)
                                        .padding(.trailing, 6)
                                        .id("hour-\(hour)")
                                }
                            }
                            
                            // Day columns with content
                            HStack(spacing: 0) {
                                ForEach(weekDays.indices, id: \.self) { index in
                                    let day = weekDays[index]
                                    DayColumn(day: day, width: dayColumnWidth, tasks: tasksForDate(day.date))
                                }
                            }
                            .padding(.trailing, scrollbarWidth) // Account for scrollbar
                        }
                    }
                }
            }
        }
    }
    
    // Day column component to improve readability
    private struct DayColumn: View {
        let day: CalendarDay
        let width: CGFloat
        let tasks: [Item]
        
        @EnvironmentObject var timeIndicatorPositioner: TimeIndicatorPositioner
        private let calendar = Calendar.current
        
        var body: some View {
            ZStack(alignment: .top) {
                // Hour backgrounds
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        ZStack {
                            // Background for the entire hour cell
                            Rectangle()
                                .fill(calendar.isDateInToday(day.date) ? Color.blue.opacity(0.03) : Color.clear)
                                .frame(width: width, height: 60)
                            
                            // Bottom divider
                            VStack {
                                Spacer()
                                Divider().background(Color.gray.opacity(0.2))
                            }
                        }
                        .frame(height: 60)
                    }
                }
                
                // Tasks
                ForEach(tasks.filter { !$0.isAllDay }, id: \.id) { task in
                    TaskEventView(task: task)
                        .frame(width: width - 4) // Subtract padding
                        .padding(.horizontal, 2)
                        .offset(y: taskOffset(for: task))
                }
                
                // Time indicator
                if calendar.isDateInToday(day.date) {
                    TimeIndicatorView()
                        .frame(width: width)
                        .environmentObject(timeIndicatorPositioner)
                }
            }
            .frame(width: width)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .trailing
            )
        }
        
        private func taskOffset(for task: Item) -> CGFloat {
            guard let taskDate = task.dueDate else { return 0 }
            let hour = calendar.component(.hour, from: taskDate)
            let minute = calendar.component(.minute, from: taskDate)
            
            // Convert to pixels based on hour height
            return CGFloat(hour) * 60 + (CGFloat(minute) / 60.0) * 60
        }
    }
    
    private func formatWeekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 1..<12: return "\(hour)a"
        case 13..<24: return "\(hour-12)p"
        default: return "\(hour)"
        }
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
}