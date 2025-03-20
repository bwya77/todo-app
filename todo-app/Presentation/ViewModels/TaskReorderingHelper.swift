//
//  TaskReorderingHelper.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// Helper class to make task reordering more reliable
class TaskReorderingHelper {
    
    /// Force refresh all persistence
    /// - Parameter context: The managed object context
    static func forceRefresh(context: NSManagedObjectContext) {
        NotificationCenter.default.post(
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: context
        )
    }
    
    /// Set proper display order values for all tasks in all projects
    /// - Parameter context: The managed object context
    static func repairProjectTaskOrder(context: NSManagedObjectContext) {
        // First, get all projects
        let projectRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(projectRequest)
            print("🔍 Found \(projects.count) projects to repair ordering")
            
            // Process each project
            for project in projects {
                repairTaskOrderForProject(project, context: context)
            }
            
            // Also handle tasks without projects (inbox)
            repairInboxTaskOrder(context: context)
            
            print("✅ Task order repair complete")
            
        } catch {
            print("❌ Failed to repair project task order: \(error)")
        }
    }
    
    /// Set proper display order for tasks in a specific project
    /// - Parameters:
    ///   - project: The project to repair
    ///   - context: The managed object context
    private static func repairTaskOrderForProject(_ project: Project, context: NSManagedObjectContext) {
        guard let projectName = project.name else { return }
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", project)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(request)
            print("📋 Repairing order for project '\(projectName)' with \(tasks.count) tasks")
            
            // Update display order for all tasks
            for (index, task) in tasks.enumerated() {
                task.displayOrder = Int32(index)
            }
            
            // Save changes
            try context.save()
            
        } catch {
            print("⚠️ Error repairing tasks for project '\(projectName)': \(error)")
        }
    }
    
    /// Set proper display order for tasks without a project (inbox)
    /// - Parameter context: The managed object context
    private static func repairInboxTaskOrder(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == nil")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)
        ]
        
        do {
            let tasks = try context.fetch(request)
            print("📋 Repairing order for Inbox with \(tasks.count) tasks")
            
            // Update display order for all tasks
            for (index, task) in tasks.enumerated() {
                task.displayOrder = Int32(index)
            }
            
            // Save changes
            try context.save()
            
        } catch {
            print("⚠️ Error repairing inbox tasks: \(error)")
        }
    }
}
