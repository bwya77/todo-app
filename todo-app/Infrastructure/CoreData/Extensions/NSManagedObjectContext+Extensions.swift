//
//  NSManagedObjectContext+Extensions.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    /// Helper method to save changes safely and report any errors
    /// - Parameter completion: Optional completion handler that returns success status and any error
    func saveContext(completion: ((Bool, Error?) -> Void)? = nil) {
        guard hasChanges else {
            completion?(true, nil)
            return
        }
        
        do {
            try save()
            completion?(true, nil)
        } catch {
            print("Error saving context: \(error)")
            completion?(false, error)
        }
    }
    
    /// Find a project by ID
    /// - Parameter id: The UUID of the project to find
    /// - Returns: The project if found, nil otherwise
    func project(withID id: UUID) -> Project? {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching project by ID: \(error)")
            return nil
        }
    }
    
    /// Find a tag by ID
    /// - Parameter id: The UUID of the tag to find
    /// - Returns: The tag if found, nil otherwise
    func tag(withID id: UUID) -> Tag? {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching tag by ID: \(error)")
            return nil
        }
    }
    
    /// Find a task by ID
    /// - Parameter id: The UUID of the task to find
    /// - Returns: The task if found, nil otherwise
    func task(withID id: UUID) -> Item? {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching task by ID: \(error)")
            return nil
        }
    }
    
    /// Get tasks due on a specific date
    /// - Parameter date: The date to find tasks for
    /// - Returns: Array of tasks due on that date
    func tasks(dueOn date: Date) -> [Item] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                          startOfDay as NSDate, 
                                          endOfDay as NSDate)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.isAllDay, ascending: false),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        do {
            return try fetch(fetchRequest)
        } catch {
            print("Error fetching tasks due on date: \(error)")
            return []
        }
    }
    
    /// Get incomplete tasks due on or before today (overdue tasks)
    /// - Returns: Array of overdue tasks
    func overdueTasks() -> [Item] {
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND dueDate < %@", today as NSDate)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        do {
            return try fetch(fetchRequest)
        } catch {
            print("Error fetching overdue tasks: \(error)")
            return []
        }
    }
    
    /// Get all projects
    /// - Returns: Array of all projects
    func allProjects() -> [Project] {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
        
        do {
            return try fetch(fetchRequest)
        } catch {
            print("Error fetching all projects: \(error)")
            return []
        }
    }
    
    /// Get all tags
    /// - Returns: Array of all tags
    func allTags() -> [Tag] {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            return try fetch(fetchRequest)
        } catch {
            print("Error fetching all tags: \(error)")
            return []
        }
    }
}
