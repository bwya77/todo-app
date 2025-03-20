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
        print("🚨 FULL RESET OF TASK ORDERING - Using proper initializer")
        
        // Use the new task order initializer for proper setup
        AppLaunchTaskOrderInitializer.shared.initializeTaskOrder()
        
        // Force save all changes to disk
        PersistentOrder.saveAllContexts()
        
        // Force UI refresh after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceUIRefresh"),
                object: nil
            )
        }

        print("✅ Full reset completed using improved persistence system")
    }
    
    /// Resets task order for a specific project
    /// - Parameters:
    ///   - project: The project to reset ordering for
    ///   - context: The NSManagedObjectContext
    static func resetProjectTaskOrder(for project: Project, in context: NSManagedObjectContext) {
        print("🔄 Resetting task order for project: \(project.name ?? "Unknown")")
        
        // Fetch tasks for this project
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("  📋 Found \(tasks.count) tasks to reorder")
            
            // Update display order sequentially with spacing
            for (index, task) in tasks.enumerated() {
                let newOrder = Int32(index * 10)
                task.setValue(newOrder, forKey: "displayOrder")
            }
            
            // Save changes
            PersistentOrder.save(context: context)
            
            // Force notification to update views
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskOrderChanged"),
                object: nil
            )
            
            print("  ✅ Project task order reset successfully")
        } catch {
            print("  ❌ Error resetting project task order: \(error)")
        }
    }
    
    /// Resets task order for Inbox (tasks without a project)
    /// - Parameter context: The NSManagedObjectContext
    static func resetInboxTaskOrder(in context: NSManagedObjectContext) {
        print("🔄 Resetting task order for Inbox")
        
        // Fetch tasks without a project
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("  📋 Found \(tasks.count) inbox tasks to reorder")
            
            // Update display order sequentially with spacing
            for (index, task) in tasks.enumerated() {
                let newOrder = Int32(index * 10)
                task.setValue(newOrder, forKey: "displayOrder")
            }
            
            // Save changes
            PersistentOrder.save(context: context)
            
            // Force notification to update views
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskOrderChanged"),
                object: nil
            )
            
            print("  ✅ Inbox task order reset successfully")
        } catch {
            print("  ❌ Error resetting inbox task order: \(error)")
        }
    }
    
    /// Resets order for both Today and Completed tasks
    /// - Parameter context: The NSManagedObjectContext
    static func resetSpecialViewsTaskOrder(in context: NSManagedObjectContext) {
        // Reset Today tasks
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayRequest: NSFetchRequest<Item> = Item.fetchRequest()
        todayRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                           today as NSDate, tomorrow as NSDate)
        
        resetTaskOrderForRequest(todayRequest, viewName: "Today", in: context)
        
        // Reset Completed tasks
        let completedRequest: NSFetchRequest<Item> = Item.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "completed == YES")
        
        resetTaskOrderForRequest(completedRequest, viewName: "Completed", in: context)
    }
    
    /// Helper to reset task order for a specific fetch request
    /// - Parameters:
    ///   - request: The NSFetchRequest to use
    ///   - viewName: Name for logging
    ///   - context: The NSManagedObjectContext
    private static func resetTaskOrderForRequest(_ request: NSFetchRequest<Item>, viewName: String, in context: NSManagedObjectContext) {
        print("🔄 Resetting task order for \(viewName) view")
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try context.fetch(request)
            print("  📋 Found \(tasks.count) tasks to reorder")
            
            // Update display order sequentially with spacing
            for (index, task) in tasks.enumerated() {
                let newOrder = Int32(index * 10)
                task.setValue(newOrder, forKey: "displayOrder")
            }
            
            // Save changes
            PersistentOrder.save(context: context)
            
            print("  ✅ \(viewName) task order reset successfully")
        } catch {
            print("  ❌ Error resetting \(viewName) task order: \(error)")
        }
    }
}
