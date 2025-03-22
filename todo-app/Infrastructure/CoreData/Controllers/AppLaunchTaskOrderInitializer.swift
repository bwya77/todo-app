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
    
    /// Ensures task and project order is properly initialized at app launch
    func initializeTaskOrder() {
        guard !hasInitialized else {
            print("✓ Order already initialized this session")
            return
        }
        
        print("🚀 Initializing order at app launch")
        let context = PersistenceController.shared.container.viewContext
        
        // Verify all items and projects have a valid displayOrder
        verifyEntityDisplayOrder(in: context)
        
        // Initialize task ordering for different views
        initializeTaskOrderByType(in: context)
        
        // Initialize project ordering
        initializeProjectOrder(in: context)
        
        // Mark as initialized to prevent duplicate work
        hasInitialized = true
        
        // Persist changes
        PersistentOrder.saveAllContexts()
        
        print("✅ App launch order initialization complete")
    }
    
    /// Verifies that all entities have a valid displayOrder attribute
    private func verifyEntityDisplayOrder(in context: NSManagedObjectContext) {
        // Verify tasks have displayOrder
        verifyTaskDisplayOrder(in: context)
        
        // Verify projects have displayOrder
        verifyProjectDisplayOrder(in: context)
    }
    
    /// Verifies that all tasks have a valid displayOrder attribute
    private func verifyTaskDisplayOrder(in context: NSManagedObjectContext) {
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
            print("❌ Error verifying task displayOrder: \(error)")
        }
    }
    
    /// Verifies that all projects have a valid displayOrder attribute
    private func verifyProjectDisplayOrder(in context: NSManagedObjectContext) {
        // Check if displayOrder exists in the model
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName["displayOrder"] != nil
        
        if !hasDisplayOrder {
            // Try to add the displayOrder attribute dynamically
            context.persistentStoreCoordinator?.managedObjectModel.addDisplayOrderAttribute()
            
            // Verify it was added
            let updatedEntity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
            let nowHasDisplayOrder = updatedEntity?.propertiesByName["displayOrder"] != nil
            
            if !nowHasDisplayOrder {
                print("⚠️ Could not add displayOrder attribute to Project entity. Skipping project order initialization.")
                return
            }
        }
        
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
        
        do {
            let projects = try context.fetch(fetchRequest)
            print("🔍 Verifying displayOrder for \(projects.count) projects")
            
            var fixedCount = 0
            
            for (index, project) in projects.enumerated() {
                // Use a safer approach for each project
                if project.value(forKey: "displayOrder") == nil {
                    // Set a default value based on alphabetical index
                    project.setValue(Int32(index * 10), forKey: "displayOrder")
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                try context.save()
                print("🔧 Fixed displayOrder for \(fixedCount) projects")
            } else {
                print("✓ All projects have displayOrder attribute")
            }
        } catch {
            print("❌ Error verifying project displayOrder: \(error)")
        }
    }
    
    /// Initialize task ordering for different task types (inbox, projects, etc.)
    private func initializeTaskOrderByType(in context: NSManagedObjectContext) {
        let types = ["inbox", "project", "today", "completed"]
        
        for type in types {
            ensureTaskOrderConsistency(for: type, in: context)
        }
    }
    
    /// Initialize project ordering
    private func initializeProjectOrder(in context: NSManagedObjectContext) {
        // Check if displayOrder exists in the model
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName["displayOrder"] != nil
        
        if !hasDisplayOrder {
            // Try to add the displayOrder attribute dynamically
            context.persistentStoreCoordinator?.managedObjectModel.addDisplayOrderAttribute()
            
            // Verify it was added
            let updatedEntity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
            let nowHasDisplayOrder = updatedEntity?.propertiesByName["displayOrder"] != nil
            
            if !nowHasDisplayOrder {
                print("⚠️ Could not add displayOrder attribute to Project entity. Skipping project order initialization.")
                return
            }
        }
        
        let projectsRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Use appropriate sort descriptors
        if hasDisplayOrder {
            projectsRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        } else {
            projectsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
        }
        
        do {
            let projects = try context.fetch(projectsRequest)
            print("🔍 Checking order for \(projects.count) projects")
            
            // Check for discontinuities in displayOrder values
            var hasOrderingIssues = false
            
            if projects.count >= 2 && hasDisplayOrder {
                for i in 0..<projects.count-1 {
                    let currentOrder = projects[i].value(forKey: "displayOrder") as? Int32 ?? 9999
                    let nextOrder = projects[i+1].value(forKey: "displayOrder") as? Int32 ?? 9999
                    
                    // Look for identical ordering values (a critical issue)
                    if currentOrder == nextOrder {
                        hasOrderingIssues = true
                        print("⚠️ Found duplicate display order values in projects")
                        break
                    }
                }
            } else if !hasDisplayOrder {
                // If displayOrder was just added, we need to initialize values
                hasOrderingIssues = true
            }
            
            // Always reindex if displayOrder was just added or if there are issues
            if hasOrderingIssues {
                print("🔄 Reindexing projects")
                for (index, project) in projects.enumerated() {
                    let newOrder = Int32(index * 10) // Use spacing for future insertions
                    project.setValue(newOrder, forKey: "displayOrder")
                }
                
                // Save changes
                try context.save()
                print("✅ Project order fixed")
            } else {
                print("✓ Project order is consistent")
            }
        } catch {
            print("❌ Error checking project order: \(error)")
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
                
                // Save changes safely
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
                    
                    // Save changes safely
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
