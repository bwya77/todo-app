//
//  Project+OrderingExtensions.swift
//  todo-app
//
//  Created on 3/20/25.
//

import Foundation
import CoreData

extension Project {
    /// The default sort order attribute name in the data model
    static let orderAttributeName = "displayOrder"
    
    /// Reorders projects
    /// - Parameters:
    ///   - from: The source index
    ///   - to: The destination index
    ///   - projects: The array of projects to reorder
    ///   - context: The managed object context to save changes in
    ///   - notifyOrderChange: Whether to post a notification that project order changed (defaults to true)
    static func reorderProjects(from: Int, to: Int, projects: [Project], context: NSManagedObjectContext, notifyOrderChange: Bool = true) {
        guard from != to, from >= 0, to >= 0, from < projects.count, to < projects.count else { return }
        
        print("🔄 CRITICAL: Direct reordering project from index \(from) to \(to)")
        
        // Check if displayOrder exists in the model
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName[orderAttributeName] != nil
        
        if !hasDisplayOrder {
            // Try to add the displayOrder attribute dynamically
            context.persistentStoreCoordinator?.managedObjectModel.addDisplayOrderAttribute()
            
            // Verify it was added
            let updatedEntity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
            let nowHasDisplayOrder = updatedEntity?.propertiesByName[orderAttributeName] != nil
            
            if !nowHasDisplayOrder {
                print("❌ Cannot reorder projects: displayOrder attribute is missing and could not be added")
                return
            }
        }
        
        // Get the project being moved
        let projectToMove = projects[from]
        
        // Create a mutable copy of the projects array
        var mutableProjects = projects
        
        // Remove the project from its current position
        mutableProjects.remove(at: from)
        
        // Insert the project at the new position
        mutableProjects.insert(projectToMove, at: to)
        
        // Update the display order of all projects - use 10-spacing to allow for insertions
        for (index, project) in mutableProjects.enumerated() {
            let newOrder = Int32(index * 10)
            print("  → Setting project '\(project.name ?? "Untitled")' display order: \(newOrder)")
            project.setValue(newOrder, forKey: "displayOrder")
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
        
        // Notify that project order has changed (for app-wide listeners)
        if notifyOrderChange {
            NotificationCenter.default.post(
                name: NSNotification.Name("ProjectOrderChanged"),
                object: nil
            )
        }
        
        print("  ✅ Successfully saved project reordering")
    }
    
    /// Get all projects in the correct display order
    /// - Parameters:
    ///   - context: The managed object context
    /// - Returns: Array of projects in the correct order
    static func getOrderedProjects(in context: NSManagedObjectContext) -> [Project] {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Check if displayOrder exists in the model
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName[orderAttributeName] != nil
        
        // Use appropriate sort descriptors
        if hasDisplayOrder {
            // Sort by display order
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: orderAttributeName, ascending: true)
            ]
        } else {
            // Fallback to name sorting
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Project.name, ascending: true)
            ]
            
            // Try to add the displayOrder attribute dynamically
            let model = context.persistentStoreCoordinator?.managedObjectModel
            model?.addDisplayOrderAttribute()
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching ordered projects: \(error)")
            return []
        }
    }
    
    /// Direct access method for display order (adding to avoid conflict with generated property)
    func getDisplayOrder() -> Int32 {
        // Use direct access to the property
        return self.value(forKey: "displayOrder") as? Int32 ?? 9999
    }
    
    /// Direct setting method for display order
    func setDisplayOrder(_ newValue: Int32) {
        // Use direct access to set the property
        self.setValue(newValue, forKey: "displayOrder")
    }
    
    /// Updates display order and persists changes
    func updateDisplayOrder(_ newOrder: Int32, save: Bool = true) {
        // Set the display order directly
        self.setDisplayOrder(newOrder)
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
                print("Saved display order \(newOrder) for project \(name ?? "unknown")")
            } catch {
                print("Error saving display order: \(error)")
            }
        }
    }
}
