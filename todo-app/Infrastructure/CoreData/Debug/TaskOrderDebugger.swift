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
    
    /// Resets task order for a project
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
            
            // Reset display order based on creation date
            for (index, task) in tasks.enumerated() {
                task.setValue(Int32(index * 10), forKey: Item.orderAttributeName)
            }
            
            // Save changes
            try context.save()
            
        } catch {
            print("❌ Failed to reset task order: \(error)")
        }
    }
}