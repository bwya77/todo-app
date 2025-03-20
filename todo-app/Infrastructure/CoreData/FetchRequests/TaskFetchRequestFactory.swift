//
//  TaskFetchRequestFactory.swift
//  todo-app
//
//  Created on 3/13/25.
//

import Foundation
import CoreData
import SwiftUI

/// A factory class for creating commonly used fetch requests for the Item entity
/// Centralizes fetch logic and improves reusability across the application
struct TaskFetchRequestFactory {
    
    // MARK: - General Fetch Requests
    
    /// Creates a fetch request for all tasks
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func allTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Always use displayOrder as primary sort
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        return request
    }
    
    // MARK: - Task Fetch Requests by Date
    
    /// Creates a fetch request for today's tasks
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func todayTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Only show incomplete tasks due today
        request.predicate = NSPredicate(format: "completed == NO AND dueDate >= %@ AND dueDate < %@", 
                                        today as NSDate, tomorrow as NSDate)
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)
        ]
        
        return request
    }
    
    /// Creates a fetch request for tasks due on a specific date
    /// - Parameters:
    ///   - date: The date to fetch tasks for
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tasksForDate(_ date: Date, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                        startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.isAllDay, ascending: false),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    /// Creates a fetch request for tasks due in a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tasksInDateRange(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                        startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    /// Creates a fetch request for upcoming tasks (due after today)
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func upcomingTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        
        // Only show incomplete tasks with due dates after today
        request.predicate = NSPredicate(format: "completed == NO AND dueDate >= %@", today as NSDate)
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    /// Creates a fetch request for overdue tasks (due before today and not completed)
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func overdueTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        
        request.predicate = NSPredicate(format: "completed == NO AND dueDate < %@", today as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    // MARK: - Task Fetch Requests by Project
    
    /// Creates a fetch request for tasks in a specific project
    /// - Parameters:
    ///   - project: The project to fetch tasks for
    ///   - includeCompleted: Whether to include completed tasks (default: false)
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tasksForProject(_ project: Project, includeCompleted: Bool = false, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        print("Fetching tasks for project: \(project.name ?? "Unknown")") // Debug log
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        let projectPredicate = NSPredicate(format: "project == %@", project)
        let predicate: NSPredicate
        
        if !includeCompleted {
            let notCompletedPredicate = NSPredicate(format: "completed == NO")
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [projectPredicate, notCompletedPredicate])
        } else {
            predicate = projectPredicate
        }
        
        request.predicate = predicate
        
        // Ensure tasks are sorted by displayOrder first - make this explicit
        request.sortDescriptors = [
            NSSortDescriptor(key: Item.orderAttributeName, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        print("Sort descriptors: \(String(describing: request.sortDescriptors))")
        
        return request
    }
    
    /// Creates a fetch request for completed tasks in a specific project
    /// - Parameters:
    ///   - project: The project to fetch tasks for
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func completedTasksForProject(_ project: Project, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        request.predicate = NSPredicate(format: "project == %@ AND completed == YES", project)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.completionDate, ascending: false)
        ]
        
        return request
    }
    
    // MARK: - Inbox Fetch Requests
    
    /// Creates a fetch request for inbox tasks (tasks without a project)
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func inboxTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Only show tasks without a project and that aren't completed
        request.predicate = NSPredicate(format: "project == nil AND completed == NO")
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: false)
        ]
        
        return request
    }
    
    // MARK: - Status-based Fetch Requests
    
    /// Creates a fetch request for completed tasks
    /// - Parameters:
    ///   - limit: Optional limit for number of tasks to fetch
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func completedTasks(limit: Int? = nil, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Always show completed tasks
        request.predicate = NSPredicate(format: "completed == YES")
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.completionDate, ascending: false)
        ]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        return request
    }
    
    /// Creates a fetch request for logged tasks (completed and marked as logged)
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func loggedTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        request.predicate = NSPredicate(format: "completed == YES AND logged == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.completionDate, ascending: false)
        ]
        
        return request
    }
    
    // MARK: - Tag-based Fetch Requests
    
    /// Creates a fetch request for tasks with a specific tag
    /// - Parameters:
    ///   - tag: The tag to fetch tasks for
    ///   - includeCompleted: Whether to include completed tasks (default: false)
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tasksWithTag(_ tag: Tag, includeCompleted: Bool = false, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        let tagPredicate = NSPredicate(format: "ANY tags == %@", tag)
        let predicate: NSPredicate
        
        if !includeCompleted {
            let notCompletedPredicate = NSPredicate(format: "completed == NO")
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [tagPredicate, notCompletedPredicate])
        } else {
            predicate = tagPredicate
        }
        
        request.predicate = predicate
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    // MARK: - Batch Size Configuration
    
    /// Configures request for efficient batch fetching, typically used for calendar views
    /// - Parameters:
    ///   - request: The fetch request to configure
    ///   - batchSize: The batch size to use (default: 20)
    /// - Returns: The configured fetch request
    static func configureBatchFetching<T>(_ request: NSFetchRequest<T>, batchSize: Int = 20) -> NSFetchRequest<T> {
        request.fetchBatchSize = batchSize
        return request
    }
    
    // MARK: - Ordered Task Fetch Requests
    
    /// Creates a fetch request with custom display order
    /// - Parameters:
    ///   - predicate: The predicate to filter tasks
    ///   - context: The managed object context
    /// - Returns: A configured fetch request sorted by display order
    static func orderedTasks(predicate: NSPredicate?, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = predicate
        
        // Primary sort by display order
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            // Fallback sorts if display order is the same
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        return request
    }
    
    // MARK: - Calendar View Fetch Requests
    
    /// Creates an optimized fetch request for calendar month view
    /// - Parameters:
    ///   - startDate: The start date of the month
    ///   - endDate: The end date of the month
    ///   - context: The managed object context
    /// - Returns: A configured fetch request optimized for calendar display
    static func calendarMonthTasks(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request = tasksInDateRange(from: startDate, to: endDate, in: context)
        
        // Configure batch fetching for optimized performance
        request.fetchBatchSize = 31 // Typical max days in a month
        
        // Add a relationship prefetch to avoid separate faults for each task's project
        request.relationshipKeyPathsForPrefetching = ["project"]
        
        return request
    }
    
    /// Creates an optimized fetch request for calendar week view
    /// - Parameters:
    ///   - startDate: The start date of the week
    ///   - endDate: The end date of the week
    ///   - context: The managed object context
    /// - Returns: A configured fetch request optimized for calendar display
    static func calendarWeekTasks(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
        let request = tasksInDateRange(from: startDate, to: endDate, in: context)
        
        // Configure batch fetching for optimized performance
        request.fetchBatchSize = 7 // Days in a week
        
        // Add a relationship prefetch to avoid separate faults for each task's project
        request.relationshipKeyPathsForPrefetching = ["project"]
        
        return request
    }
}
