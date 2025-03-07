import SwiftUI
import CoreData
import AppKit

struct CompactWeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    // Add state for scrollbar width and container width
    @State private var scrollbarWidth: CGFloat = 16 // Default value
    @State private var containerWidth: CGFloat = 0
    
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
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let scrollbarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
            let contentWidth = availableWidth - scrollbarWidth
            
            VStack(spacing: 0) {
                // Week header with very compact design - NO MONTH TITLE
                weekHeaderView(width: contentWidth)
                    .zIndex(1)
                    .background(Color.white)
                    .frame(width: contentWidth)
                
                // Scrollable time grid - account for scrollbar width
                weekTimeGridView(width: contentWidth)
                    .frame(width: availableWidth) // Full width to include scrollbar
            }
            .onAppear {
                // Save container width for calculations
                self.containerWidth = availableWidth
                self.scrollbarWidth = scrollbarWidth
            }
        }
    }
    
    // Instead of calculating column width, we'll use GeometryReader
    // and flexible layouts to ensure columns align properly
    
    // Break up the complex view into smaller components
    private func weekHeaderView(width: CGFloat) -> some View {
        // Calculate column width for each day (7 days in a week)
        let columnWidth = (width - 40) / 7 // 40 is the time label width
        
        return VStack(spacing: 0) {
            // Day headers - minimal height (removed month title)
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
                        .frame(width: columnWidth)
                        .background(CalendarColors.backgroundColorForDate(day.date))
                        .onTapGesture {
                            selectedDate = day.date
                        }
                    }
                }
            }
            .frame(width: width)
            
            // Super compact All Day section with no spacing
            HStack(spacing: 0) {
                // All day label - match time label width exactly
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
                            .frame(width: columnWidth)
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
            .frame(width: width)
        }
    }
    
    private func weekTimeGridView(width: CGFloat) -> some View {
        // Calculate column width for each day (7 days in a week)
        let columnWidth = (width - 40) / 7 // 40 is the time label width
        
        return ScrollView(.vertical, showsIndicators: true) {
            ScrollViewReader { scrollViewProxy in 
                VStack(spacing: 0) {
                    // Time grid
                    HStack(spacing: 0) {
                        // Time labels - exact same width as 'All day' label
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
                        
                        // Days with events - exactly aligned with day headers
                        HStack(spacing: 0) {
                            ForEach(weekDays, id: \.id) { day in
                                timeGridColumn(for: day, width: columnWidth)
                                    .frame(width: columnWidth, alignment: .leading) // Fixed width for consistency
                            }
                        }
                        .padding(.trailing, 0) // No padding to ensure alignment
                    }
                }
                .onAppear {
                    // Update scrollbar width measurement
                    DispatchQueue.main.async {
                        scrollbarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
                    }
                    
                    // Scroll to 7am by default for a reasonable starting position
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollViewProxy.scrollTo("hour-7", anchor: .top)
                        }
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                // Update scrollbar width on gesture to handle appearance/disappearance 
                DispatchQueue.main.async {
                    scrollbarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
                }
            }
        )
        .environmentObject(TimeIndicatorPositioner.shared)
    }
    
    // Helper function to create a single day column in the time grid
    @ViewBuilder
    private func timeGridColumn(for day: CalendarDay, width: CGFloat? = nil) -> some View {
        let columnWidth = width ?? ((containerWidth - 40) / 7)
        
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
        .frame(width: columnWidth)
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
