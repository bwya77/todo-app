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
    @State private var scrollOffset: CGFloat = 400 // Start position around 8am (8*60 = 480px)
    
    private let calendar = Calendar.current
    
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
    
    // Calculate dynamic height for all-day section (min 20, max for 4 tasks)
    private var allDayHeight: CGFloat {
        let maxTaskCount = weekDays.reduce(0) { result, day in
            let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }.count
            return max(result, dayTasks)
        }
        
        // Each task is about 24px high + padding
        return min(max(25, CGFloat(maxTaskCount * 24 + 10)), 120)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week calendar implementation
            ScrollView(.vertical, showsIndicators: true) {
                ScrollViewReader { scrollViewProxy in 
                    VStack(spacing: 0) {
                        // Day headers
                        HStack(spacing: 0) {
                            // Empty space above time scale
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 50)
                            
                            // Day headers
                            HStack(spacing: 0) {
                                ForEach(weekDays, id: \.id) { day in
                                    VStack(spacing: 4) {
                                        Text(formatWeekdayShort(from: day.date))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(calendar.isDateInToday(day.date) ? .blue : .primary)
                                        
                                        // Day number with selected styling
                                        ZStack {
                                            if selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!) {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 28, height: 28)
                                            }
                                            
                                            Text("\(calendar.component(.day, from: day.date))")
                                                .font(.headline)
                                                .fontWeight(calendar.isDateInToday(day.date) ? .bold : .regular)
                                                .foregroundColor(selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!) 
                                                                ? .white : (calendar.isDateInToday(day.date) ? .blue : .primary))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture {
                                        selectedDate = day.date
                                    }
                                }
                            }
                        }
                        
                        // All Day section
                        HStack(spacing: 0) {
                            // All day label
                            Text("All day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(height: allDayHeight)
                                .frame(width: 50, alignment: .trailing)
                                .padding(.trailing, 6)
                                .background(Color.gray.opacity(0.05))
                            
                            // All day events per day
                            HStack(spacing: 0) {
                                ForEach(weekDays, id: \.id) { day in
                                    let dayTasks = tasksForDate(day.date).filter { $0.isAllDay }
                                    
                                    // All Day tasks container
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.05))
                                        .frame(height: allDayHeight)
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
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        
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
                                        .padding(.trailing, 6)
                                        .id("hour-\(hour)")
                                }
                            }
                            
                            // Days with events
                            HStack(spacing: 0) {
                                ForEach(weekDays, id: \.id) { day in
                                    // Single day column
                                    timeGridColumn(for: day)
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to a reasonable starting hour (8am)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                scrollViewProxy.scrollTo("hour-8", anchor: .top)
                            }
                        }
                    }
                }
            }
            .environmentObject(TimeIndicatorPositioner.shared)
        }
    }
    
    // Helper function to create a single day column in the time grid
    @ViewBuilder
    private func timeGridColumn(for day: CalendarDay) -> some View {
        ZStack(alignment: .top) {
            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 60)
                    Divider()
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
                TimeIndicatorView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
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
