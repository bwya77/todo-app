//
//  WeekCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

struct WeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    @State private var scrollOffset: CGFloat = 400
    
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
    
    // Get regular (non-all-day) tasks for a specific date
    private func regularTasksForDate(_ date: Date) -> [Item] {
        return tasksForDate(date).filter { !$0.isAllDay }
    }
    
    // Calculate offset for a task in the time grid
    private func taskOffset(for task: Item) -> CGFloat {
        guard let taskDate = task.dueDate else { return 0 }
        
        let hour = calendar.component(.hour, from: taskDate)
        let minute = calendar.component(.minute, from: taskDate)
        
        // Calculate offset based on hour and minute (each hour is 60px tall)
        return CGFloat(hour * 60 + minute)
    }
    
    // Get all all-day tasks for the week to calculate dynamic height
    private var allWeekAllDayTasks: [Item] {
        let allDayTasks = weekDays.flatMap { day in
            return tasksForDate(day.date).filter { $0.isAllDay }
        }
        return allDayTasks
    }
    
    // Calculate dynamic height for all-day section - reduced heights
    private var allDayHeight: CGFloat {
        let maxTaskCount = weekDays.reduce(0) { result, day in
            let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }.count
            return max(result, dayTasks)
        }
        
        // If there are no tasks, use a minimal height
        if maxTaskCount == 0 {
            return 22 // Reduced minimal height for empty all-day section
        }
        
        // Each task is about 20px high + minimal padding
        return min(max(22, CGFloat(maxTaskCount * 20 + 2)), 80)
    }
    
    var body: some View {
        VStack(spacing: 0) { // Zero spacing to ensure no gaps
            // Header area with reduced shadow
            weekHeaderView()
                .zIndex(1)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1) // Smaller, subtler shadow
            
            // Scrollable time grid - directly connected to header with no gap
            weekTimeGridView()
        }
    }
    
    // Break up the complex view into smaller components
    private func weekHeaderView() -> some View {
        VStack(spacing: 0) {
            // Month title - reduced padding and height
            HStack {
                Text(monthFormatter.string(from: visibleMonth))
                    .font(.headline)
                    .padding(.leading, 8)
                Spacer()
            }
            .frame(height: 24) // Reduced height
            .padding(.bottom, 0) // Removed bottom padding
            
            // Day headers - reduced vertical padding for more compact display
            HStack(spacing: 0) {
                // Empty space above time scale
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50)
                
                // Day headers
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.id) { day in
                        VStack(spacing: 0) {
                            Text(formatWeekdayShort(from: day.date))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                            
                            Text("\(calendar.component(.day, from: day.date))")
                                .font(.subheadline)
                                .fontWeight(calendar.isDateInToday(day.date) ? .bold : .regular)
                                .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                        }
                        .padding(.vertical, 2) // Reduced vertical padding
                        .frame(maxWidth: .infinity)
                        .background(CalendarColors.backgroundColorForDate(day.date))
                        .onTapGesture {
                            selectedDate = day.date
                        }
                    }
                }
            }
            // Add separator line to visually separate day headers from all-day section
            Divider().background(AppColors.calendarGridlineColor)
            
            // All Day section - no vertical spacing between day headers and all-day
            HStack(spacing: 0) {
                // All day label
                Text("All day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: allDayHeight)
                    .frame(width: 50, alignment: .trailing)
                    .padding(.trailing, 4)
                    .padding(.top, 0) // Ensure no top padding
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(AppColors.calendarGridlineColor, lineWidth: 0.5)
                    )
                
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
                                            AllDayTaskRow(task: task)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(AppColors.calendarGridlineColor, lineWidth: 0.5)
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
                                    .frame(width: 50, alignment: .trailing)
                                    .padding(.trailing, 4)
                                    .id("hour-\(hour)")
                                    .background(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(AppColors.calendarGridlineColor, lineWidth: 0.5)
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
                    Divider().background(AppColors.calendarGridlineColor)
                }
            }
            
            // Events
            VStack(spacing: 0) {
                ForEach(regularTasksForDate(day.date), id: \.id) { task in
                    TaskEventView(task: task)
                        .padding(.horizontal, 4)
                        .offset(y: taskOffset(for: task))
                }
            }
            
            // Time indicator for today
            if calendar.isDateInToday(day.date) {
                WeekTimeIndicatorView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .environmentObject(TimeIndicatorPositioner.shared)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(AppColors.calendarGridlineColor),
            alignment: .trailing
        )
    }
    
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
        case 0: return "12 AM"
        case 12: return "Noon"
        case 1..<12: return "\(hour) AM"
        case 13..<24: return "\(hour-12) PM"
        default: return "\(hour)"
        }
    }
}
