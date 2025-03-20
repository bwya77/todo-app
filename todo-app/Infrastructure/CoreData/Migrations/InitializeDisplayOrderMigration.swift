//
//  InitializeDisplayOrderMigration.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// A utility function to initialize display order for all tasks
/// This is used as a fallback if normal migration doesn't work
struct InitializeDisplayOrderMigration {
    
    /// Initialize display order for all tasks
    /// - Parameter context: The managed object context
    static func initializeDisplayOrder(in context: NSManagedObjectContext) {
        print("🔄 Initializing display order for all tasks...")
        
        // Fetch all tasks
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let items = try context.fetch(fetchRequest)
            print("📉 Found \(items.count) tasks to update")
            
            // Group by project
            let itemsByProject = Dictionary(grouping: items) { item in
                item.project?.id?.uuidString ?? "no-project"
            }
            
            print("🗂️ Tasks grouped into \(itemsByProject.count) projects")
            
            // Initialize display order for each group
            for (projectId, projectItems) in itemsByProject {
                var order: Int32 = 0
                
                // Sort items by createdDate within each project
                let sortedItems = projectItems.sorted { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
                
                print("🏷️ Setting display order for project ID \(projectId) with \(sortedItems.count) tasks")
                
                for item in sortedItems {
                    // Use setValue with the correct attribute name constant
                    item.setValue(order, forKey: Item.orderAttributeName)
                    order += 1
                }
            }
            
            // Save changes
            try context.save()
            print("✅ Display order initialized for \(items.count) tasks")
            
            // Force a fetch results controller refresh by posting a notification
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
            
        } catch {
            print("❌ Failed to initialize display order: \(error)")
        }
    }
    
    /// Initialize display order specifically for inbox tasks (tasks without a project)
    /// - Parameter context: The managed object context
    static func initializeInboxDisplayOrder(in context: NSManagedObjectContext) {
        print("🔄 Initializing display order for inbox tasks...")
        
        // Fetch all inbox tasks (tasks without a project)
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == nil")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let items = try context.fetch(fetchRequest)
            print("📉 Found \(items.count) inbox tasks to update")
            
            // Update display order sequentially with spacing (like in projects)
            for (index, item) in items.enumerated() {
                let order = Int32(index * 10) // Use spacing for future insertions
                print("  → Setting inbox task '\(item.title ?? "Untitled")' display order: \(order)")
                item.setValue(order, forKey: Item.orderAttributeName)
            }
            
            // Save changes
            try context.save()
            print("✅ Display order initialized for inbox tasks")
            
            // Force a notification to update all views
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
            
        } catch {
            print("❌ Failed to initialize inbox display order: \(error)")
        }
    }
    
    /// Force immediate re-initialization of display order for a specific project
    /// - Parameters:
    ///   - project: The project to update task ordering for
    ///   - context: The managed object context
    static func forceReInitializeProjectDisplayOrder(for project: Project, in context: NSManagedObjectContext) {
        print("🔄 Force re-initializing display order for project: \(project.name ?? "Unknown")")
        
        // Fetch all tasks for this project
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let items = try context.fetch(fetchRequest)
            print("📉 Found \(items.count) tasks to update for project")
            
            // Update display order sequentially
            for (index, item) in items.enumerated() {
                // Use setValue with the correct attribute name constant
                print("  → Setting task '\(item.title ?? "Untitled")' display order: \(index)")
                item.setValue(Int32(index), forKey: Item.orderAttributeName)
            }
            
            // Update project modification date
            project.lastModifiedDate = Date()
            
            // Save changes
            try context.save()
            print("✅ Display order re-initialized for project tasks")
            
            // Force a notification to update all views
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
            
        } catch {
            print("❌ Failed to re-initialize project display order: \(error)")
        }
    }
}
