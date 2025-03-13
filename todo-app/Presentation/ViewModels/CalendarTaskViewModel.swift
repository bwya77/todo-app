//
//  CalendarTaskViewModel.swift
//  todo-app
//
//  Created on 3/13/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI

/// Specialized ViewModel for calendar views with batch fetching optimization
class CalendarTaskViewModel: ObservableObject {
    // MARK: - Properties
    
    /// The managed object context
    private let viewContext: NSManagedObjectContext
    
    /// Current tasks organized by date
    @Published private(set) var tasksByDate: [Date: [Item]] = [:]
    
    /// All tasks in the current date range
    @Published private(set) var allTasks: [Item] = []
    
    /// Current date range being displayed
    private var currentStartDate: Date?
    private var currentEndDate: Date?
    
    /// Calendar for date calculations
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Fetch Operations
    
    /// Fetches tasks for a month view
    /// - Parameters:
    ///   - date: Any date in the month
    ///   - includingAdjacentMonthDays: Whether to include tasks from adjacent months that appear in the calendar grid
    func fetchTasksForMonth(containing date: Date, includingAdjacentMonthDays: Bool = true) {
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else { return }
        
        // Get the first day of the next month
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return }
        
        // If including adjacent days, adjust start/end dates based on calendar grid
        var adjustedStartDate = startOfMonth
        var adjustedEndDate = startOfNextMonth
        
        if includingAdjacentMonthDays {
            // Get the weekday of the first day (1-7, with 1 being Sunday in Gregorian calendar)
            let firstWeekday = calendar.component(.weekday, from: startOfMonth)
            
            // Adjust to get the first day shown on calendar (may be from previous month)
            let daysToSubtract = (firstWeekday - calendar.firstWeekday + 7) % 7
            if daysToSubtract > 0 {
                adjustedStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth)!
            }
            
            // Calculate last day shown on calendar (may be from next month)
            // First, get the last day of the month
            let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth)!
            
            // Get the weekday of the last day
            let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
            
            // Calculate days to add to include the full last week
            let daysToAdd = (calendar.firstWeekday + 6 - lastWeekday) % 7
            if daysToAdd > 0 {
                adjustedEndDate = calendar.date(byAdding: .day, value: daysToAdd, to: lastDayOfMonth)!
                // Ensure we're getting the end of that day
                adjustedEndDate = calendar.date(byAdding: .day, value: 1, to: adjustedEndDate)!
            }
        }
        
        // Store current range
        currentStartDate = adjustedStartDate
        currentEndDate = adjustedEndDate
        
        // Fetch tasks using the optimized fetch request
        fetchTasks(from: adjustedStartDate, to: adjustedEndDate, asBatch: true)
    }
    
    /// Fetches tasks for a week view
    /// - Parameter date: Any date in the week
    func fetchTasksForWeek(containing date: Date) {
        // Get the first day of the week containing the date
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) else { return }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return }
        
        // Store current range
        currentStartDate = startOfWeek
        currentEndDate = endOfWeek
        
        // Fetch tasks using the optimized fetch request
        fetchTasks(from: startOfWeek, to: endOfWeek, asBatch: true)
    }
    
    /// Fetches tasks for a specific date range
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - asBatch: Whether to use batch fetching optimization
    private func fetchTasks(from startDate: Date, to endDate: Date, asBatch: Bool = false) {
        // Create the fetch request
        let fetchRequest: NSFetchRequest<Item>
        
        if asBatch {
            // Use the optimized factory method for batch fetching
            fetchRequest = TaskFetchRequestFactory.calendarMonthTasks(from: startDate, to: endDate, in: viewContext)
        } else {
            fetchRequest = TaskFetchRequestFactory.tasksInDateRange(from: startDate, to: endDate, in: viewContext)
        }
        
        // Perform the fetch
        do {
            let fetchedTasks = try viewContext.fetch(fetchRequest)
            
            // Store all tasks
            self.allTasks = fetchedTasks
            
            // Organize tasks by date
            self.tasksByDate = organizeTasksByDate(fetchedTasks)
        } catch {
            print("Error fetching calendar tasks: \(error)")
        }
    }
    
    /// Organizes tasks by their due date
    /// - Parameter tasks: The tasks to organize
    /// - Returns: Dictionary with date keys and task arrays
    private func organizeTasksByDate(_ tasks: [Item]) -> [Date: [Item]] {
        var tasksByDate: [Date: [Item]] = [:]
        
        for task in tasks {
            guard let dueDate = task.dueDate else { continue }
            
            // Get the start of the day for the due date
            let startOfDay = calendar.startOfDay(for: dueDate)
            
            // Add task to the appropriate day
            if tasksByDate[startOfDay] == nil {
                tasksByDate[startOfDay] = []
            }
            tasksByDate[startOfDay]?.append(task)
        }
        
        // Sort tasks within each day
        for (date, tasks) in tasksByDate {
            let sortedTasks = tasks.sorted { (task1, task2) -> Bool in
                // First by all-day status (all-day tasks first)
                if task1.isAllDay && !task2.isAllDay {
                    return true
                } else if !task1.isAllDay && task2.isAllDay {
                    return false
                }
                
                // Then by time
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                }
                
                // Then by priority (higher priority first)
                return task1.priority > task2.priority
            }
            
            tasksByDate[date] = sortedTasks
        }
        
        return tasksByDate
    }
    
    /// Gets tasks for a specific date
    /// - Parameter date: The date to get tasks for
    /// - Returns: Array of tasks due on that date
    func tasksForDate(_ date: Date) -> [Item] {
        let startOfDay = calendar.startOfDay(for: date)
        return tasksByDate[startOfDay] ?? []
    }
    
    /// Refreshes the current fetch to update data
    func refreshCurrentFetch() {
        guard let startDate = currentStartDate, let endDate = currentEndDate else { return }
        fetchTasks(from: startDate, to: endDate, asBatch: true)
    }
    
    /// Gets all dates in the current range that have tasks
    /// - Returns: Array of dates with tasks
    func datesWithTasks() -> [Date] {
        return Array(tasksByDate.keys).sorted()
    }
    
    // MARK: - Task Operations
    
    /// Add a task on a specific date
    /// - Parameters:
    ///   - title: The task title
    ///   - date: The due date
    ///   - isAllDay: Whether it's an all-day task
    ///   - priority: Task priority
    ///   - project: The project the task belongs to
    ///   - notes: Optional notes
    func addTask(title: String, date: Date, isAllDay: Bool = false, priority: Int16 = 0, project: Project? = nil, notes: String? = nil) {
        let newItem = Item(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.createdDate = Date()
        newItem.dueDate = date
        newItem.isAllDay = isAllDay
        newItem.priority = priority
        newItem.completed = false
        newItem.project = project
        newItem.notes = notes
        
        saveContext()
        
        // Refresh the data
        refreshCurrentFetch()
    }
    
    /// Updates an existing task
    /// - Parameters:
    ///   - task: The task to update
    ///   - title: Optional new title
    ///   - dueDate: Optional new due date
    ///   - isAllDay: Optional all-day status
    ///   - priority: Optional new priority
    ///   - project: Optional new project
    ///   - notes: Optional new notes
    func updateTask(_ task: Item, title: String? = nil, dueDate: Date? = nil, isAllDay: Bool? = nil, priority: Int16? = nil, project: Project? = nil, notes: String? = nil) {
        // Update the task properties
        if let title = title {
            task.title = title
        }
        if let dueDate = dueDate {
            task.dueDate = dueDate
        }
        if let isAllDay = isAllDay {
            task.isAllDay = isAllDay
        }
        if let priority = priority {
            task.priority = priority
        }
        if let project = project {
            task.project = project
        }
        if let notes = notes {
            task.notes = notes
        }
        
        saveContext()
        
        // Refresh data since due date might have changed
        refreshCurrentFetch()
    }
    
    /// Toggles a task's completion status
    /// - Parameter task: The task to toggle
    func toggleTaskCompletion(_ task: Item) {
        task.toggleCompletion(save: true)
        
        // Refresh data
        refreshCurrentFetch()
    }
    
    /// Deletes a task
    /// - Parameter task: The task to delete
    func deleteTask(_ task: Item) {
        viewContext.delete(task)
        saveContext()
        
        // Refresh data
        refreshCurrentFetch()
    }
    
    // MARK: - Context Operations
    
    /// Saves the managed object context
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
}
