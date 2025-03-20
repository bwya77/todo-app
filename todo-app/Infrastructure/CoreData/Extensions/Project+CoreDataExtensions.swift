//
//  Project+CoreDataExtensions.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

extension Project {
    // Remove the lastModifiedDate property to avoid crashing
    // @NSManaged var lastModifiedDate: Date?
    /// Validates and ensures all required properties are set correctly
    func validateAndSetDefaults() {
        // Ensure ID is set
        if id == nil {
            id = UUID()
        }
        
        // Ensure name is never nil
        if name == nil {
            name = "Untitled Project"
        }
        
        // Ensure color is set with a default
        if color == nil {
            color = "gray"
        }
    }
    
    /// Creates a new Project with required properties
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the project in
    ///   - name: The name of the project
    ///   - color: The color of the project (defaults to gray)
    ///   - notes: Optional notes for the project
    /// - Returns: The newly created Project
    static func create(in context: NSManagedObjectContext, name: String, color: String = "gray", notes: String? = nil) -> Project {
        let project = Project(context: context)
        project.id = UUID()
        project.name = name
        project.color = color
        project.notes = notes
        return project
    }
    
    /// Get all tasks from this project (excluding completed and logged tasks)
    /// - Returns: Array of active tasks
    func activeTasks() -> [Item] {
        guard let items = items as? Set<Item> else { return [] }
        return items.filter { !$0.completed && !$0.logged }.sorted {
            // Sort by due date (nil dates at the end), then by priority
            if let date1 = $0.dueDate, let date2 = $1.dueDate {
                return date1 < date2
            } else if $0.dueDate != nil {
                return true
            } else if $1.dueDate != nil {
                return false
            } else {
                return $0.priority > $1.priority
            }
        }
    }
    
    /// Get all completed tasks from this project (including logged tasks)
    /// - Returns: Array of completed tasks
    func completedTasks() -> [Item] {
        guard let items = items as? Set<Item> else { return [] }
        return items.filter { $0.completed }.sorted {
            // Sort by completion date (newer first)
            if let date1 = $0.completionDate, let date2 = $1.completionDate {
                return date1 > date2
            } else if $0.completionDate != nil {
                return true
            } else if $1.completionDate != nil {
                return false
            } else {
                return $0.createdDate ?? Date() > $1.createdDate ?? Date()
            }
        }
    }
    
    /// Get the count of active (incomplete) tasks in this project
    var activeTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.filter { !$0.completed && !$0.logged }.count
    }
    
    /// Get the count of completed tasks in this project
    var completedTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.filter { $0.completed }.count
    }
    
    /// Get the count of all tasks in this project
    var totalTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.count
    }
    
    /// Calculate the completion percentage of this project
    var completionPercentage: Double {
        guard totalTaskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
    
    /// Mark all completed tasks in this project as logged
    /// - Parameter save: Whether to save the context after making changes
    func logAllCompletedTasks(save: Bool = true) {
        guard let items = items as? Set<Item> else { return }
        
        for item in items {
            if item.completed {
                item.logged = true
            }
        }
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving after logging tasks: \(error)")
            }
        }
    }
    
    /// Add a new task to this project
    /// - Parameters:
    ///   - title: The title of the task
    ///   - dueDate: Optional due date
    ///   - priority: Task priority (defaults to .none)
    ///   - isAllDay: Whether this is an all-day task
    ///   - notes: Optional notes for the task
    ///   - save: Whether to save the context after adding
    /// - Returns: The newly created task
    @discardableResult
    func addTask(title: String, 
               dueDate: Date? = nil,
               priority: Priority = .none,
               isAllDay: Bool = false,
               notes: String? = nil,
               save: Bool = true) -> Item {
        
        guard let context = managedObjectContext else {
            fatalError("Attempted to add task to project without a valid context")
        }
        
        let task = Item.create(in: context, 
                             title: title, 
                             dueDate: dueDate, 
                             priority: priority,
                             isAllDay: isAllDay,
                             project: self,
                             notes: notes)
        
        if save {
            do {
                try context.save()
            } catch {
                print("Error saving after adding task to project: \(error)")
            }
        }
        
        return task
    }
}
