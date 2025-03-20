//
//  Item+OrderingExtensions.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

extension Item {
    /// The default sort order attribute name in the data model
    static let orderAttributeName = "displayOrder"
    
    /// Reorders tasks within the same project or section
    /// - Parameters:
    ///   - from: The source index
    ///   - to: The destination index
    ///   - tasks: The array of tasks to reorder
    ///   - context: The managed object context to save changes in
    ///   - notifyOrderChange: Whether to post a notification that task order changed (defaults to true)
    static func reorderTasks(from: Int, to: Int, tasks: [Item], context: NSManagedObjectContext, notifyOrderChange: Bool = true) {
        guard from != to, from >= 0, to >= 0, from < tasks.count, to < tasks.count else { return }
        
        print("🔄 CRITICAL: Direct reordering task from index \(from) to \(to)")
        
        // Get the task being moved
        let taskToMove = tasks[from]
        
        // Create a mutable copy of the tasks array
        var mutableTasks = tasks
        
        // Remove the task from its current position
        mutableTasks.remove(at: from)
        
        // Insert the task at the new position
        mutableTasks.insert(taskToMove, at: to)
        
        // Update the display order of all tasks - use 10-spacing to allow for insertions
        for (index, task) in mutableTasks.enumerated() {
            let newOrder = Int32(index * 10)
            print("  → Setting task '\(task.title ?? "Untitled")' display order: \(newOrder)")
            task.setValue(newOrder, forKey: "displayOrder")
        }
        
        // Use the PersistentOrder class to ensure changes are saved to disk
        PersistentOrder.save(context: context)
        
        // Force a notification to update all views
        NotificationCenter.default.post(
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: context
        )
        
        // Also post a special notification for UI refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("ForceUIRefresh"),
            object: nil
        )
        
        // Notify that task order has changed (for app-wide listeners)
        if notifyOrderChange {
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskOrderChanged"),
                object: nil
            )
        }
        
        print("  ✅ Successfully saved reordering")
    }
    
    /// Get the tasks in the correct display order for a project
    /// - Parameters:
    ///   - project: The project to get tasks for (nil for Inbox tasks)
    ///   - context: The managed object context
    ///   - includeCompleted: Whether to include completed tasks
    /// - Returns: Array of tasks in the correct order
    static func getOrderedTasks(for project: Project?, in context: NSManagedObjectContext, includeCompleted: Bool = false) -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Create appropriate predicate based on project and completion status
        var predicates: [NSPredicate] = []
        
        if let project = project {
            predicates.append(NSPredicate(format: "project == %@", project))
        } else {
            predicates.append(NSPredicate(format: "project == nil"))
        }
        
        if !includeCompleted {
            predicates.append(NSPredicate(format: "completed == NO"))
        }
        
        // Combine predicates
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Sort by display order
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: orderAttributeName, ascending: true)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching ordered tasks: \(error)")
            return []
        }
    }
}
