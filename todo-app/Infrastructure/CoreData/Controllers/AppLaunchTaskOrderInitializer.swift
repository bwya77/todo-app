//
//  AppLaunchTaskOrderInitializer.swift
//  todo-app
//
//  Created on 3/20/25.
//

import Foundation
import CoreData
import SwiftUI

/// Responsible for ensuring task order is properly initialized at app launch
class AppLaunchTaskOrderInitializer {
    /// Singleton instance
    static let shared = AppLaunchTaskOrderInitializer()
    
    /// Flag to track whether initialization has been performed
    private var hasInitialized = false
    
    private init() {}
    
    /// Ensures task order is properly initialized at app launch
    func initializeTaskOrder() {
        guard !hasInitialized else {
            print("✓ Task order already initialized this session")
            return
        }
        
        print("🚀 Initializing task order at app launch")
        let context = PersistenceController.shared.container.viewContext
        
        // Verify all items have a valid displayOrder
        verifyDisplayOrderExists(in: context)
        
        // Initialize task ordering for different views
        initializeTaskOrderByType(in: context)
        
        // Mark as initialized to prevent duplicate work
        hasInitialized = true
        
        // Persist changes
        PersistentOrder.saveAllContexts()
        
        print("✅ App launch task order initialization complete")
    }
    
    /// Verifies that all tasks have a valid displayOrder attribute
    private func verifyDisplayOrderExists(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            print("🔍 Verifying displayOrder for \(items.count) tasks")
            
            var fixedCount = 0
            
            for item in items {
                if item.value(forKey: "displayOrder") == nil {
                    // Set a default value
                    item.setValue(9999, forKey: "displayOrder")
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                try context.save()
                print("🔧 Fixed displayOrder for \(fixedCount) tasks")
            } else {
                print("✓ All tasks have displayOrder attribute")
            }
        } catch {
            print("❌ Error verifying displayOrder: \(error)")
        }
    }
    
    /// Initialize task ordering for different task types (inbox, projects, etc.)
    private func initializeTaskOrderByType(in context: NSManagedObjectContext) {
        let types = ["inbox", "project", "today", "completed"]
        
        for type in types {
            ensureTaskOrderConsistency(for: type, in: context)
        }
    }
    
    /// Check and repair task ordering for a specific type (inbox, project, etc.)
    private func ensureTaskOrderConsistency(for type: String, in context: NSManagedObjectContext) {
        // Fetch tasks depending on type
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        switch type {
        case "inbox":
            fetchRequest.predicate = NSPredicate(format: "project == nil")
        case "project":
            // Handle projects one by one
            ensureProjectsTaskOrderConsistency(in: context)
            return
        case "today":
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            fetchRequest.predicate = NSPredicate(format: "completed == NO AND dueDate >= %@ AND dueDate < %@",
                                               today as NSDate, tomorrow as NSDate)
        case "completed":
            fetchRequest.predicate = NSPredicate(format: "completed == YES")
        default:
            return
        }
        
        // Always sort by displayOrder first, then other criteria
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true),
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(fetchRequest)
            print("🔄 Checking task order for \(type): \(tasks.count) tasks")
            
            // Check for discontinuities in displayOrder values
            var hasOrderingIssues = false
            
            if tasks.count >= 2 {
                for i in 0..<tasks.count-1 {
                    let currentOrder = tasks[i].getDisplayOrder()
                    let nextOrder = tasks[i+1].getDisplayOrder()
                    
                    // Look for identical ordering values (a critical issue)
                    if currentOrder == nextOrder {
                        hasOrderingIssues = true
                        print("⚠️ Found duplicate display order values in \(type) tasks")
                        break
                    }
                }
            }
            
            // Only reindex if there are issues or specifically requested
            if hasOrderingIssues {
                print("🔄 Reindexing \(type) tasks")
                for (index, task) in tasks.enumerated() {
                    let newOrder = Int32(index * 10) // Use spacing for future insertions
                    task.setValue(newOrder, forKey: "displayOrder")
                }
                
                // Save changes
                try context.save()
                print("✅ Task order fixed for \(type)")
            } else {
                print("✓ Task order for \(type) is consistent")
            }
        } catch {
            print("❌ Error checking task order for \(type): \(error)")
        }
    }
    
    /// Check and repair task ordering for all projects
    private func ensureProjectsTaskOrderConsistency(in context: NSManagedObjectContext) {
        let projectsRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(projectsRequest)
            print("🔍 Checking task order for \(projects.count) projects")
            
            for project in projects {
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "project == %@", project)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
                
                let tasks = try context.fetch(fetchRequest)
                
                // Skip empty projects
                if tasks.isEmpty {
                    continue
                }
                
                print("  Checking project: \(project.name ?? "Unknown") (\(tasks.count) tasks)")
                
                // Check for discontinuities in displayOrder values
                var hasOrderingIssues = false
                
                if tasks.count >= 2 {
                    for i in 0..<tasks.count-1 {
                        let currentOrder = tasks[i].getDisplayOrder()
                        let nextOrder = tasks[i+1].getDisplayOrder()
                        
                        // Look for identical ordering values (a critical issue)
                        if currentOrder == nextOrder {
                            hasOrderingIssues = true
                            print("  ⚠️ Found duplicate display order values")
                            break
                        }
                    }
                }
                
                // Only reindex if there are issues
                if hasOrderingIssues {
                    print("  🔄 Reindexing project tasks")
                    for (index, task) in tasks.enumerated() {
                        let newOrder = Int32(index * 10) // Use spacing for future insertions
                        task.setValue(newOrder, forKey: "displayOrder")
                    }
                    
                    // Save changes
                    try context.save()
                    print("  ✅ Task order fixed")
                } else {
                    print("  ✓ Task order is consistent")
                }
            }
        } catch {
            print("❌ Error checking project task order: \(error)")
        }
    }
}
