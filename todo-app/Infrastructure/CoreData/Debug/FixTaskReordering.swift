//
//  FixTaskReordering.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData
import SwiftUI

/// Emergency fix for task reordering issues
struct FixTaskReordering {
    
    /// Resets and repairs the display order for the entire database
    static func resetEverything() {
        let context = PersistenceController.shared.container.viewContext
        print("🚨 FULL RESET OF TASK ORDERING")
        
        // 1. Set displayOrder property for all tasks
        fixDisplayOrderProperty(in: context)
        
        // 2. Reindex all projects
        reindexAllProjects(in: context)
        
        // 3. Reindex inbox
        reindexInbox(in: context)
        
        // 4. Force save all changes to disk
        PersistentOrder.saveAllContexts()
        
        // Try again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Send a special notification to force UI refresh
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceUIRefresh"),
                object: nil
            )
        }

        print("✅ Full reset completed. Please restart the app.")
    }
    
    /// Fix any items that don't have a displayOrder set
    private static func fixDisplayOrderProperty(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let allItems = try context.fetch(fetchRequest)
            print("🔍 Checking displayOrder for \(allItems.count) tasks")
            
            var fixedCount = 0
            
            for item in allItems {
                // Check if displayOrder is accessible
                if item.value(forKey: "displayOrder") == nil {
                    // Set a default value
                    item.setValue(999, forKey: "displayOrder")
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                try context.save()
                print("🔧 Fixed missing displayOrder for \(fixedCount) tasks")
            } else {
                print("✓ All tasks have displayOrder property")
            }
        } catch {
            print("❌ Error fixing displayOrder: \(error)")
        }
    }
    
    /// Reindex all projects with sequential display order
    private static func reindexAllProjects(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(fetchRequest)
            print("🗂️ Reindexing \(projects.count) projects")
            
            for project in projects {
                reindexTasksForProject(project, in: context)
            }
            
            print("✓ All projects reindexed")
        } catch {
            print("❌ Error reindexing projects: \(error)")
        }
    }
    
    /// Reindex all tasks in a specific project with sequential display order
    private static func reindexTasksForProject(_ project: Project, in context: NSManagedObjectContext) {
        guard let _ = project.id else {
            print("⚠️ Project has no ID, skipping")
            return
        }
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("  📋 Reindexing \(tasks.count) tasks for project: \(project.name ?? "Unknown")")
            
            for (index, task) in tasks.enumerated() {
                task.setValue(Int32(index * 10), forKey: "displayOrder")
            }
            
            // Use persistent order saving instead of just context.save()
            PersistentOrder.save(context: context)
            
            // Force the change to be recognized
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                object: context
            )
            
            print("  ✓ Project tasks reindexed")
        } catch {
            print("  ❌ Error reindexing project tasks: \(error)")
        }
    }
    
    /// Reindex inbox (tasks with no project)
    private static func reindexInbox(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("📥 Reindexing \(tasks.count) tasks in Inbox")
            
            for (index, task) in tasks.enumerated() {
                task.setValue(Int32(index * 10), forKey: "displayOrder")
            }
            
            // Use persistent order saving instead of just context.save()
            PersistentOrder.save(context: context)
            
            // Force the change to be recognized
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                object: context
            )
            
            print("✓ Inbox tasks reindexed")
        } catch {
            print("❌ Error reindexing inbox tasks: \(error)")
        }
    }
}
