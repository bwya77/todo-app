import SwiftUI
import CoreData

struct CompactWeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    // Month formatter for header
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
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
    
    // Calculate dynamic height for all-day section
    private var allDayHeight: CGFloat {
        let maxTaskCount = weekDays.reduce(0) { result, day in
            let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }.count
            return max(result, dayTasks)
        }
        
        // If there are no tasks, use a minimal height
        if maxTaskCount == 0 {
            return 20 // Very minimal height for empty all-day section
        }
        
        // Each task row has minimal height
        return min(max(20, CGFloat(maxTaskCount * 20 + 2)), 60)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header with very compact design
            weekHeaderView()
                .zIndex(1)
                .background(Color.white)
            
            // Scrollable time grid
            weekTimeGridView()
        }
    }
    
    // Break up the complex view into smaller components
    private func weekHeaderView() -> some View {
        VStack(spacing: 0) {
            // Ultra compact month title
            Text(monthFormatter.string(from: visibleMonth))
                .font(.subheadline)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            
            // Day headers - minimal height
            HStack(spacing: 0) {
                // Time scale label space
                Text("")
                    .frame(width: 40)
                
                // Day headers
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.id) { day in
                        VStack(spacing: 0) {
                            Text(formatWeekdayShort(from: day.date))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                            
                            Text("\(calendar.component(.day, from: day.date))")
                                .font(.caption)
                                .fontWeight(calendar.isDateInToday(day.date) ? .bold : .regular)
                                .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                        }
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
                        .background(CalendarColors.backgroundColorForDate(day.date))
                        .onTapGesture {
                            selectedDate = day.date
                        }
                    }
                }
            }
            
            // Super compact All Day section with no spacing
            HStack(spacing: 0) {
                // All day label
                Text("All day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: allDayHeight)
                    .frame(width: 40, alignment: .trailing)
                    .padding(.trailing, 2)
                    .background(Color.white)
                
                // All day events per day
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.id) { day in
                        let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }
                        
                        // All Day tasks container
                        Rectangle()
                            .fill(CalendarColors.backgroundColorForDate(day.date))
                            .frame(height: allDayHeight)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                VStack(alignment: .leading, spacing: 1) {
                                    if !dayTasks.isEmpty {
                                        ForEach(dayTasks, id: \.id) { task in
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
            }
        }
    }
    
    private func weekTimeGridView() -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            ScrollViewReader { scrollViewProxy in 
                VStack(spacing: 0) {
                    // Time grid
                    HStack(spacing: 0) {
                        // Time labels
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(height: 60)
                                    .frame(width: 40, alignment: .trailing)
                                    .padding(.trailing, 2)
                                    .id("hour-\(hour)")
                                    .background(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                        }
                        
                        // Days with events
                        HStack(spacing: 0) {
                            ForEach(weekDays, id: \.id) { day in
                                timeGridColumn(for: day)
                            }
                        }
                    }
                }
                .onAppear {
                    // Scroll to 7am by default for a reasonable starting position
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollViewProxy.scrollTo("hour-7", anchor: .top)
                        }
                    }
                }
            }
        }
        .environmentObject(TimeIndicatorPositioner.shared)
    }
    
    // Helper function to create a single day column in the time grid
    @ViewBuilder
    private func timeGridColumn(for day: CalendarDay) -> some View {
        ZStack(alignment: .top) {
            // Background color based on weekday/weekend
            Rectangle()
                .fill(CalendarColors.backgroundColorForDate(day.date))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear) // Make this clear so the background shows through
                        .frame(height: 60)
                    Divider().background(Color.gray.opacity(0.2))
                }
            }
            
            // Events
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
                    .environmentObject(TimeIndicatorPositioner.shared)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
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

// Compact All Day Task Row for Week view
struct CompactAllDayTaskRow: View {
    let task: Item
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(task.completed ? Color.gray : Color.red)
                .frame(width: 5, height: 5)
            
            Text(task.title ?? "")
                .font(.system(size: 9))
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red.opacity(0.1))
        )
    }
}
