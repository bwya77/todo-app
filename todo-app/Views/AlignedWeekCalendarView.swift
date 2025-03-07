import SwiftUI
import CoreData
import AppKit

/// A new implementation that properly handles alignment between header and time grid
struct AlignedWeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    @EnvironmentObject var timeIndicatorPositioner: TimeIndicatorPositioner
    
    // Constants
    private let timeColumnWidth: CGFloat = 40
    private let calendar = Calendar.current
    
    // Format short weekday name
    private func formatWeekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    // Calculate offset for a task in the time grid
    private func taskOffset(for task: Item) -> CGFloat {
        guard let taskDate = task.dueDate else { return 0 }
        
        let hour = calendar.component(.hour, from: taskDate)
        let minute = calendar.component(.minute, from: taskDate)
        
        // Calculate offset based on hour and minute (each hour is 60px tall)
        return CGFloat(hour * 60 + minute)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let scrollBarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
            let dayColumnWidth = (availableWidth - timeColumnWidth - scrollBarWidth) / 7
            
            VStack(spacing: 0) {
                // Day headers row (Sun, Mon, Tue, etc)
                HStack(spacing: 0) {
                    // Empty space above time column
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: timeColumnWidth)
                    
                    // Day headers
                    ForEach(weekDays, id: \.id) { day in
                        VStack(spacing: 2) {
                            Text(formatWeekdayShort(from: day.date))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                            
                            Text("\(calendar.component(.day, from: day.date))")
                                .font(.caption)
                                .fontWeight(calendar.isDateInToday(day.date) ? .bold : .regular)
                                .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                        }
                        .frame(width: dayColumnWidth, height: 24)
                        .background(CalendarColors.backgroundColorForDate(day.date))
                        .onTapGesture {
                            selectedDate = day.date
                        }
                    }
                    
                    // Empty scrollbar spacer
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: scrollBarWidth)
                }
                
                // All day events row - make it compact with fixed height
                HStack(spacing: 0) {
                    // All day label
                    Text("All day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: 20) // Fixed compact height
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 2)
                    
                    // All day events
                    HStack(spacing: 0) {
                        ForEach(weekDays, id: \.id) { day in
                            let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }
                            
                            Rectangle()
                                .fill(CalendarColors.backgroundColorForDate(day.date))
                                .frame(height: 20) // Fixed compact height
                                .frame(width: dayColumnWidth)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 1) {
                                        if !dayTasks.isEmpty {
                                            ForEach(dayTasks.prefix(1), id: \.id) { task in // Show only 1 task
                                                CompactAllDayTaskRow(task: task)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                    }
                    
                    // Empty scrollbar spacer
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: scrollBarWidth)
                }
                
                // Main time grid
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(spacing: 0) {
                        // Time labels
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(height: 60)
                                    .frame(width: timeColumnWidth, alignment: .trailing)
                                    .padding(.trailing, 2)
                                    .background(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(AppColors.calendarGridlineColor, lineWidth: 0.5)
                                    )
                            }
                        }
                        
                        // Day columns with events
                        ForEach(weekDays, id: \.id) { day in
                            dayTimeGridColumn(for: day, width: dayColumnWidth)
                        }
                    }
                }
                .id("timeGrid") // For scrolling
            }
            .onAppear {
                // Scroll to 7am by default
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        // Implementation of scrolling would go here
                    }
                }
            }
        }
    }
    
    // Time grid column for a single day
    @ViewBuilder
    private func dayTimeGridColumn(for day: CalendarDay, width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Background color
            Rectangle()
                .fill(CalendarColors.backgroundColorForDate(day.date))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 60)
                    Divider().background(AppColors.calendarGridlineColor)
                }
            }
            
            // Events for this day
            VStack(spacing: 0) {
                ForEach(regularTasksForDate(day.date), id: \.id) { task in
                    TaskEventView(task: task)
                        .padding(.horizontal, 2)
                        .offset(y: taskOffset(for: task))
                }
            }
            
            // Time indicator for today
            if calendar.isDateInToday(day.date) {
                TimeIndicatorView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 2)
                    .environmentObject(timeIndicatorPositioner)
            }
        }
        .frame(width: width)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(AppColors.calendarGridlineColor),
            alignment: .trailing
        )
    }
    
    // Get regular (non-all-day) tasks for a specific date
    private func regularTasksForDate(_ date: Date) -> [Item] {
        return tasksForDate(date).filter { !$0.isAllDay }
    }
    
    // Get tasks for a specific date
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    private var weekDays: [CalendarDay] {
        let today = visibleMonth
        
        // Find start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: 1 - weekday, to: today)!
        
        var days: [CalendarDay] = []
        
        // Create 7 days (Sunday through Saturday)
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                days.append(CalendarDay(date: date, isCurrentMonth: calendar.isDate(date, equalTo: today, toGranularity: .month)))
            }
        }
        
        return days
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
}
