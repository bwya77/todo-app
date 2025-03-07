//
//  DayCalendarViewNew.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI
import CoreData

struct DayCalendarViewNew: View {
    @Binding var selectedDate: Date?
    let tasks: [Item]
    @EnvironmentObject var timePositioner: TimeIndicatorPositioner
    
    // Callbacks for day navigation
    var onNextDay: () -> Void
    var onPreviousDay: () -> Void
    
    // Store current visible date to keep it displayed in header
    @State private var currentVisibleDate: Date = Date()
    
    // Track if navigation is in progress
    @State private var isNavigating = false
    
    // Track swipe gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var dragInProgress = false
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDateInToday(selected)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header with persistent date information
            HStack {
                // Left chevron
                Button(action: {
                    onPreviousDay()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Day indicator
                Text(dayHeaderString(for: currentVisibleDate))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(calendar.isDateInToday(currentVisibleDate) ? .blue : .primary)
                
                Spacer()
                
                // Right chevron
                Button(action: {
                    onNextDay()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 8)
            }
            .frame(height: 36)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.95))
            
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
        .onAppear {
            // Set initial visible date from selectedDate
            if let selectedDate = selectedDate {
                currentVisibleDate = selectedDate
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Update visible date when selected date changes externally
            if let newDate = newValue {
                currentVisibleDate = newDate
            }
        }
        // Add our direct gesture handling to the outer container
        .contentShape(Rectangle()) // Make the entire area tappable
        .gesture(
            // Custom DragGesture with controlled behavior
            DragGesture(minimumDistance: 30) // Reduced from 60 to 30 for better sensitivity
                .onChanged { value in
                    // Only respond if we're not already navigating
                    if !isNavigating {
                        dragInProgress = true
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    // Only proceed if we're not already navigating and this is primarily a horizontal gesture
                    if !isNavigating && dragInProgress && 
                       abs(value.translation.width) > abs(value.translation.height) * 1.5 &&
                       abs(value.translation.width) > 30 { // Reduced from 60 to 30
                        
                        // Set navigating flag to prevent multiple transitions
                        isNavigating = true
                        
                        // Determine direction
                        if value.translation.width > 0 {
                            // Right swipe = previous day
                            onPreviousDay()
                        } else {
                            // Left swipe = next day
                            onNextDay()
                        }
                        
                        // Reset after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Reduced from 1.0 to 0.5 for better responsiveness
                            self.isNavigating = false
                        }
                    }
                    
                    // Reset gesture tracking
                    dragInProgress = false
                    dragOffset = 0
                }
        )
    }
    
    // Add a method to navigate days with proper navigation guard
    private func navigateDay(direction: Int) {
        // Prevent navigation if already navigating
        if isNavigating {
            return
        }
        
        // Set navigating flag to prevent multiple navigations
        isNavigating = true
        
        // Navigate by exactly one day
        if let newDate = calendar.date(byAdding: .day, value: direction, to: currentVisibleDate) {
            self.currentVisibleDate = newDate
            self.selectedDate = newDate
        }
        
        // Reset the navigation flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Reduced from 1.2 to 0.5 for better responsiveness
            self.isNavigating = false
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
        formatter.dateFormat = "EEE d MMM" // Added month to make date more clear
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
