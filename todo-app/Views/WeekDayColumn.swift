//
//  WeekDayColumn.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

struct WeekDayColumn: View {
    let day: CalendarDay
    let isSelected: Bool
    let tasks: [Item]
    let onSelect: () -> Void
    let allDayHeight: CGFloat
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            VStack(spacing: 4) {
                Text(dayOfWeekString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .blue : .primary)
                
                // Day number with selected styling
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                    }
                    
                    Text("\(calendar.component(.day, from: day.date))")
                        .font(.headline)
                        .fontWeight(isToday || isSelected ? .bold : .regular)
                        .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .onTapGesture(perform: onSelect)
            
            // All Day section container
            Rectangle()
                .fill(Color.gray.opacity(0.05))
                .frame(height: allDayHeight)
                .overlay(
                    VStack(alignment: .leading, spacing: 1) {
                        // All day tasks
                        if !allDayTasks.isEmpty {
                            ForEach(allDayTasks, id: \.id) { task in
                                AllDayTaskRow(task: task)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                )
            .padding(.bottom, 1) // Small gap between all-day and time grid
            
            // Time grid with events
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
                    ForEach(regularTasks, id: \.id) { task in
                        TaskEventView(task: task)
                            .padding(.horizontal, 4)
                            .offset(y: taskOffset(for: task))
                    }
                }
                
                // Time indicator for today
                if isToday {
                    TimeIndicatorView()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .environmentObject(TimeIndicatorPositioner.shared)
                }
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
    
    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }
    
    // Get all-day tasks for this day
    private var allDayTasks: [Item] {
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: day.date) && task.isAllDay
        }
    }
    
    // Get regular (non-all-day) tasks for this day
    private var regularTasks: [Item] {
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: day.date) && !task.isAllDay
        }
    }
    
    private func taskOffset(for task: Item) -> CGFloat {
        guard let taskDate = task.dueDate else { return 0 }
        
        let hour = calendar.component(.hour, from: taskDate)
        let minute = calendar.component(.minute, from: taskDate)
        
        // Calculate offset based on hour and minute (each hour is 60px tall)
        return CGFloat(hour * 60 + minute)
    }
}
