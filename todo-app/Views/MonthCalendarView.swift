//
//  MonthCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

struct MonthCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    // Track if a day is selected - will be used for double-click handling
    private var isDaySelected: Bool {
        selectedDate != nil
    }
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 0)
            // Add a horizontal divider with zero padding
            Divider()
                .padding(0)
            
            // Calendar grid with gesture support
            GeometryReader { geometry in
                ZStack {
                    LazyVGrid(columns: columns, spacing: 0) {
                        // Day cells with grid lines
                        ForEach(days, id: \.id) { day in
                            CalendarDayCellView(
                                day: day,
                                isSelected: selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!),
                                onSelect: {
                                    selectedDate = day.date
                                },
                                tasks: tasksForDate(day.date)
                            )
                            .handleDoubleClick(selectedDate: $selectedDate, date: day.date) {
                                // Direct notification call on double-click
                                print("Double-clicked day: \(day.date)")
                                NotificationCenter.default.post(
                                    name: CalendarKitView.switchToDayViewNotification,
                                    object: nil,
                                    userInfo: ["date": day.date]
                                )
                            }
                            .frame(height: geometry.size.height / 6.001) // Force division to fill entire height
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Calculate all visible days for the month
    private var days: [CalendarDay] {
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: visibleMonth)
        let firstDayOfMonth = calendar.date(from: components)!
        
        // Get the weekday of the first day (0-based where 0 is Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30
        
        var days: [CalendarDay] = []
        
        // Add days from the previous month to fill the first row
        if firstWeekday > 0 {
            for dayOffset in (1...firstWeekday).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDayOfMonth) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // Add days from the current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(CalendarDay(date: date, isCurrentMonth: true))
            }
        }
        
        // Add days from the next month to complete the grid
        let remainingCells = 42 - days.count // 6 rows of 7 days
        if remainingCells > 0 {
            let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDayOfMonth)!
            for day in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: day, to: lastDayOfMonth) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
}

struct CalendarDayCellView: View {
    let day: CalendarDay
    let isSelected: Bool
    let onSelect: () -> Void
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Day number
            Text("\(calendar.component(.day, from: day.date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.leading, 4)
            
            // Actual tasks displayed (up to 3)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(task.completed ? Color.gray.opacity(0.7) : Color.pink.opacity(0.8))
                            .frame(width: 8, height: 8)
                        
                        Text(task.title ?? "")
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(task.completed ? .gray : .primary)
                            .strikethrough(task.completed)
                    }
                    .padding(.horizontal, 4)
                }
                
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            Spacer()
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .padding(1)
    }
    
    private var textColor: Color {
        if !day.isCurrentMonth {
            return Color.gray.opacity(0.5)
        } else if isToday {
            return Color.blue
        } else {
            return Color.primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.15)
        } else if isToday {
            return Color.blue.opacity(0.08)
        } else if day.isCurrentMonth {
            return Color.white
        } else {
            // Slightly different background for days outside current month
            return Color.gray.opacity(0.03)
        }
    }
}
