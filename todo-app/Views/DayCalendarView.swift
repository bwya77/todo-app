//
//  DayCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

struct DayCalendarView: View {
    @Binding var selectedDate: Date?
    let tasks: [Item]
    @EnvironmentObject var timePositioner: TimeIndicatorPositioner
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDateInToday(selected)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            if let selectedDate = selectedDate {
                Text(dayHeaderString(for: selectedDate))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .foregroundColor(isToday ? .blue : .primary)
            }
            
            // All Day section
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("All day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                        .padding(.trailing, 6)
                    
                    Spacer()
                }
                .frame(height: 25)
                .background(Color.gray.opacity(0.05))
                
                // All day tasks
                VStack(spacing: 1) {
                    if !allDayTasks.isEmpty {
                        ForEach(allDayTasks, id: \.id) { task in
                            AllDayTaskRow(task: task)
                        }
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
            }
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // Day view implementation
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    ZStack {
                        // Content
                        VStack(spacing: 0) {
                            // Time scale with events
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(spacing: 0) {
                                    // Time label
                                    Text(formatHour(hour))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 50, alignment: .trailing)
                                        .padding(.trailing, 8)
                                    
                                    // Event space
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 60)
                                            .id("hour-\(hour)")
                                        
                                        // Display tasks that fall within this hour
                                        ForEach(tasksInHour(hour), id: \.id) { task in
                                            TaskEventView(task: task)
                                                .padding(.leading, 4)
                                        }
                                    }
                                }
                                .frame(height: 60)
                                
                                // Hour divider
                                Divider()
                            }
                        }
                        .padding()
                        
                        // Overlay time indicator for today
                        if isToday {
                            TimeIndicatorView()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                                .padding(.leading, 54) // Align with content area
                                .environmentObject(TimeIndicatorPositioner.shared)
                                .zIndex(100) // Ensure it's above everything
                        }
                    }
                    .onAppear {
                        // Scroll to current hour if viewing today
                        if isToday {
                            let currentHour = Calendar.current.component(.hour, from: Date())
                            // Aim to position a bit before the current hour for better visibility
                            let targetHour = max(currentHour - 1, 0)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollViewProxy.scrollTo("hour-\(targetHour)", anchor: .top)
                                }
                            }
                        } else {
                            // If not today, start at 8am by default
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollViewProxy.scrollTo("hour-8", anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // All day tasks for the selected date
    private var allDayTasks: [Item] {
        guard let selectedDate = selectedDate else { return [] }
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            
            // Only include tasks that are for the selected date and marked as all day
            return calendar.isDate(dueDate, inSameDayAs: selectedDate) && task.isAllDay
        }
    }
    
    private func tasksInHour(_ hour: Int) -> [Item] {
        guard let selectedDate = selectedDate else { return [] }
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            
            // Check if it's the same date
            if !calendar.isDate(dueDate, inSameDayAs: selectedDate) {
                return false
            }
            
            // Skip all-day tasks (they're shown in the all-day section)
            if task.isAllDay {
                return false
            }
            
            // Check if it falls within the hour
            let taskHour = calendar.component(.hour, from: dueDate)
            return taskHour == hour
        }
    }
    
    // Format day header (e.g., "Sun 27")
    private func dayHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
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
