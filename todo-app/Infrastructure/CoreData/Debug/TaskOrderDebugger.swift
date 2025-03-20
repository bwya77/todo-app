//
//  TaskOrderDebugger.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// A debugging utility to help diagnose task ordering issues
struct TaskOrderDebugger {
    
    /// Logs the display order for tasks in a project
    /// - Parameters:
    ///   - project: The project to inspect
    ///   - context: The managed object context
    static func logTaskOrder(for project: Project, in context: NSManagedObjectContext) {
        // Fetch all tasks for this project with a display order sort
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Item.orderAttributeName, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("\n📊 Task order for project: \(project.name ?? "Unknown") [\(tasks.count) tasks]")
            print("----------------------------------------")
            
            for (index, task) in tasks.enumerated() {
                let displayOrder = task.value(forKey: Item.orderAttributeName) as? Int32 ?? -1
                print("Task \(index): \"\(task.title ?? "Untitled")\" - displayOrder: \(displayOrder)")
            }
            
            print("----------------------------------------\n")
        } catch {
            print("❌ Failed to fetch tasks for order debugging: \(error)")
        }
    }
    
    /// Resets display order for all tasks in a project
    /// - Parameters:
    ///   - project: The project to reset
    ///   - context: The managed object context
    static func resetTaskOrder(for project: Project, in context: NSManagedObjectContext) {
        // Fetch all tasks for this project with a creation date sort
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("🔄 Resetting display order for \(tasks.count) tasks in project: \(project.name ?? "Unknown")")
            
            // Reset display order based on creation date
            for (index, task) in tasks.enumerated() {
                task.setValue(Int32(index), forKey: Item.orderAttributeName)
                print("  Setting task '\(task.title ?? "Untitled")' display order: \(index)")
            }
            
            // Save changes
            try context.save()
            print("✅ Display order reset for project tasks")
            
            // Force a notification to update all views
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
            
            // Log the new order
            logTaskOrder(for: project, in: context)
            
        } catch {
            print("❌ Failed to reset task order: \(error)")
        }
    }
}
