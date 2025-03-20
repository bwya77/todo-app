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
    
    /// Verifies the integrity of display order values for a project's tasks
    /// - Parameters:
    ///   - project: The project to check
    ///   - context: The managed object context
    static func verifyDisplayOrderIntegrity(for project: Project, in context: NSManagedObjectContext) {
        // Fetch all tasks for this project with a display order sort
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Item.orderAttributeName, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("\n🔍 Verifying display order integrity for project: \(project.name ?? "Unknown")")
            
            // Check for gaps and duplicates in display order values
            var orderValues = Set<Int32>()
            var hasDuplicates = false
            var hasGaps = false
            var previousOrder: Int32? = nil
            
            for (_, task) in tasks.enumerated() {
                let displayOrder = task.value(forKey: Item.orderAttributeName) as? Int32 ?? -1
                
                // Check for duplicates
                if orderValues.contains(displayOrder) {
                    print("  ⚠️ DUPLICATE order value \(displayOrder) for task '\(task.title ?? "Untitled")'")
                    hasDuplicates = true
                }
                
                // Check for gaps (only after the first item)
                if let prevOrder = previousOrder, displayOrder > prevOrder + 1 {
                    print("  ⚠️ GAP in order values: \(prevOrder) to \(displayOrder)")
                    hasGaps = true
                }
                
                orderValues.insert(displayOrder)
                previousOrder = displayOrder
            }
            
            // Print summary
            if !hasDuplicates && !hasGaps {
                print("  ✅ All display order values are unique and sequential")
            } else {
                print("  ⚠️ Display order integrity issues found:")
                if hasDuplicates { print("    - Duplicate values detected") }
                if hasGaps { print("    - Gaps in sequence detected") }
            }
            
            print("----------------------------------------\n")
        } catch {
            print("❌ Failed to verify display order integrity: \(error)")
        }
    }
    
    /// Logs task reordering operations to help diagnose issues
    /// - Parameters:
    ///   - fromIndex: Source index
    ///   - toIndex: Destination index
    ///   - tasks: The tasks being reordered
    ///   - section: Section ID or name
    static func logReorderingOperation(
        fromIndex: Int,
        toIndex: Int,
        tasks: [Item],
        in section: String
    ) {
        guard fromIndex >= 0 && fromIndex < tasks.count,
              toIndex >= 0 && toIndex <= tasks.count else {
            print("⚠️ Invalid indices for reordering: from \(fromIndex) to \(toIndex) (count: \(tasks.count))")
            return
        }
        
        let taskTitle = tasks[fromIndex].title ?? "Untitled"
        
        print("\n🔄 REORDERING LOG: Moving task '\(taskTitle)' from position \(fromIndex) to \(toIndex) in section '\(section)'")
        print("Before reordering:")
        for (i, task) in tasks.enumerated() {
            let displayOrder = task.value(forKey: Item.orderAttributeName) as? Int32 ?? -1
            let highlight = i == fromIndex ? ">>> " : "    "
            print("\(highlight)[\(i)] '\(task.title ?? "Untitled")' - order: \(displayOrder)")
        }
        
        // Create a mutable copy of the tasks array to simulate the move
        var mutableTasks = tasks
        let movedTask = mutableTasks.remove(at: fromIndex)
        mutableTasks.insert(movedTask, at: toIndex)
        
        print("After reordering (simulation):")
        for (i, task) in mutableTasks.enumerated() {
            let displayOrder = task.value(forKey: Item.orderAttributeName) as? Int32 ?? -1
            let highlight = i == toIndex ? ">>> " : "    "
            print("\(highlight)[\(i)] '\(task.title ?? "Untitled")' - order: \(displayOrder)")
        }
        
        print("----------------------------------------\n")
    }
    
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
            
            // Verify the integrity of the display order
            verifyDisplayOrderIntegrity(for: project, in: context)
            
        } catch {
            print("❌ Failed to reset task order: \(error)")
        }
    }
}