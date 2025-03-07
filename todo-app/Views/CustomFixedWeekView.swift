import SwiftUI
import CoreData
import AppKit

struct CustomFixedWeekView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    @EnvironmentObject var timeIndicatorPositioner: TimeIndicatorPositioner
    
    // Constants
    private let timeColumnWidth: CGFloat = 90
    private let allDayRowHeight: CGFloat = 24
    private let calendar = Calendar.current
    private let exactGridLineColor = Color(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0)
    
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
                    
                    // Day headers - no separators as requested
                    ForEach(0..<7, id: \.self) { i in
                        let day = weekDays[i]
                        Text(formatWeekdayShort(from: day.date) + " " + String(calendar.component(.day, from: day.date)))
                            .font(.caption)
                            .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                            .frame(width: dayColumnWidth)
                    }
                }
                .frame(height: 25)
                .overlay(Rectangle().fill(exactGridLineColor).frame(height: 1), alignment: .bottom)
                
                // All-day row (fixed)
                HStack(spacing: 0) {
                    // Time label
                    Text("All Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: allDayRowHeight)
                        .frame(width: timeColumnWidth - 30, alignment: .center)
                        .padding(.trailing, 8)
                    
                    Divider().background(exactGridLineColor)
                    
                    // All-day content with explicit vertical lines
                    HStack(spacing: 0) {
                        ForEach(0..<weekDays.count, id: \.self) { index in
                            if index > 0 {
                                Divider().background(exactGridLineColor)
                            }
                            
                            // Day cell
                            ZStack {
                                let day = weekDays[index]
                                let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }
                                
                                // Background for today
                                Rectangle()
                                    .fill(calendar.isDateInToday(day.date) ? Color.blue.opacity(0.03) : Color.clear)
                                
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
                                            Text("+" + String(dayTasks.count-1) + " more")
                                                .font(.system(size: 8))
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                        }
                                    }
                                }
                                .frame(width: dayColumnWidth - 1, alignment: .leading) // Account for divider
                            }
                            .frame(width: index == 0 ? dayColumnWidth : dayColumnWidth - 1) // Account for divider
                        }
                    }
                }
                .frame(height: allDayRowHeight)
                .background(Color.white)
                .overlay(Rectangle().fill(exactGridLineColor).frame(height: 1), alignment: .bottom)
                
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
                                        .frame(width: timeColumnWidth - 16, alignment: .trailing)
                                        .padding(.trailing, 8)
                                        .id("hour-" + String(hour))
                                }
                            }
                            
                            Divider().background(exactGridLineColor)
                            
                            // Day columns with content and explicit dividers
                            HStack(spacing: 0) {
                                ForEach(0..<weekDays.count, id: \.self) { index in
                                    if index > 0 {
                                        Divider().background(exactGridLineColor)
                                    }
                                    
                                    // Day column
                                    let day = weekDays[index]
                                    ZStack(alignment: .top) {
                                        // Background color and hour lines
                                        VStack(spacing: 0) {
                                            ForEach(0..<24, id: \.self) { hour in
                                                ZStack {
                                                    // Background for today
                                                    Rectangle()
                                                        .fill(calendar.isDateInToday(day.date) ? Color.blue.opacity(0.03) : Color.clear)
                                                    
                                                    // Bottom divider
                                                    VStack {
                                                        Spacer()
                                                        Divider().background(exactGridLineColor)
                                                    }
                                                }
                                                .frame(height: 60)
                                            }
                                        }
                                        
                                        // Tasks
                                        ForEach(tasksForDate(day.date).filter { !$0.isAllDay }, id: \.id) { task in
                                            TaskEventView(task: task)
                                                .frame(width: dayColumnWidth - 5) // Subtract padding and divider
                                                .padding(.horizontal, 2)
                                                .offset(y: taskOffset(for: task))
                                        }
                                        
                                        // Time indicator
                                        if calendar.isDateInToday(day.date) {
                                            TimeIndicatorView()
                                                .frame(width: dayColumnWidth - 1) // Account for divider
                                                .environmentObject(timeIndicatorPositioner)
                                        }
                                    }
                                    .frame(width: index == 0 ? dayColumnWidth : dayColumnWidth - 1) // Account for divider
                                }
                            }
                            .padding(.trailing, scrollbarWidth) // Account for scrollbar
                        }
                    }
                }
            }
        }
    }
    
    private func taskOffset(for task: Item) -> CGFloat {
        guard let taskDate = task.dueDate else { return 0 }
        let hour = calendar.component(.hour, from: taskDate)
        let minute = calendar.component(.minute, from: taskDate)
        
        // Convert to pixels based on hour height
        return CGFloat(hour) * 60 + (CGFloat(minute) / 60.0) * 60
    }
    
    private func formatWeekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0: return "12 AM  "
        case 12: return "12 PM  "
        case 1..<12: return String(hour) + " AM  "
        case 13..<24: return String(hour-12) + " PM  "
        default: return String(hour)
        }
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
}
