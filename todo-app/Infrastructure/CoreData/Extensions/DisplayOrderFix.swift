//
//  DisplayOrderFix.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

// Direct approach to add displayOrder attribute to CoreData model at runtime
extension NSManagedObjectModel {
    /// Adds the displayOrder attribute to the Item and Project entities if they don't exist
    func addDisplayOrderAttribute() {
        // Add to Item entity
        addDisplayOrderToEntity("Item")
        
        // Add to Project entity
        addDisplayOrderToEntity("Project")
    }
    
    /// Helper method to add displayOrder to an entity
    private func addDisplayOrderToEntity(_ entityName: String) {
        if let entity = entitiesByName[entityName] {
            // Check if displayOrder property already exists
            if entity.propertiesByName["displayOrder"] == nil {
                // Create the new attribute
                let displayOrderAttribute = NSAttributeDescription()
                displayOrderAttribute.name = "displayOrder"
                displayOrderAttribute.attributeType = .integer32AttributeType
                displayOrderAttribute.defaultValue = 0
                displayOrderAttribute.isOptional = false
                
                // Add it to the entity's properties
                var properties = entity.properties
                properties.append(displayOrderAttribute)
                entity.properties = properties
                
                print("✅ Added displayOrder attribute to \(entityName) entity")
            } else {
                print("ℹ️ displayOrder attribute already exists for \(entityName)")
            }
        } else {
            print("❌ Could not find \(entityName) entity in model")
        }
    }
}

/// Critical utility for management of display order for both tasks and projects
class DisplayOrderManager {
    /// Ensures all tasks and projects have display order attribute by adding it to the model if needed,
    /// and checking existing items
    static func ensureDisplayOrderExists() {
        print("🔍 Ensuring displayOrder attribute exists for all items")
        
        // Get current model
        let container = PersistenceController.shared.container
        let model = container.managedObjectModel
        
        // Add the attribute to the model
        model.addDisplayOrderAttribute()
        
        // Get the context
        let context = container.viewContext
        
        // Fetch all tasks and ensure they have displayOrder
        ensureItemsHaveDisplayOrder(context)
        
        // Fetch all projects and ensure they have displayOrder
        ensureProjectsHaveDisplayOrder(context)
        
        print("✅ Ensured displayOrder attribute exists for all entities")
    }
    
    /// Ensure all Item entities have displayOrder
    private static func ensureItemsHaveDisplayOrder(_ context: NSManagedObjectContext) {
        do {
            // Fetch all tasks
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            
            let items = try context.fetch(fetchRequest)
            print("📊 Found \(items.count) tasks to check")
            
            var fixedCount = 0
            
            // Check each item for displayOrder property
            for item in items {
                if item.value(forKey: "displayOrder") == nil {
                    // Set a default value
                    item.setValue(999, forKey: "displayOrder")
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                // Save changes safely
                try? context.save()
                print("🔧 Fixed displayOrder for \(fixedCount) tasks")
            } else {
                print("✓ All tasks have displayOrder attribute")
            }
        } catch {
            print("❌ Error ensuring task displayOrder exists: \(error)")
        }
    }
    
    /// Ensure all Project entities have displayOrder
    private static func ensureProjectsHaveDisplayOrder(_ context: NSManagedObjectContext) {
        do {
            // Fetch all projects
            let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
            
            let projects = try context.fetch(fetchRequest)
            print("📊 Found \(projects.count) projects to check")
            
            var fixedCount = 0
            
            // Check each project for displayOrder property
            for (index, project) in projects.enumerated() {
                if project.value(forKey: "displayOrder") == nil {
                    // Set a default value based on index to preserve alphabetical order
                    project.setValue(Int32(index * 10), forKey: "displayOrder")
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                // Save changes safely
                try? context.save()
                print("🔧 Fixed displayOrder for \(fixedCount) projects")
            } else {
                print("✓ All projects have displayOrder attribute")
            }
        } catch {
            print("❌ Error ensuring project displayOrder exists: \(error)")
        }
    }
    
    /// Repair task ordering for all items
    /// Sorts tasks by creation date and assigns new incremental display order values
    static func repairAllTaskOrder() {
        print("🔧 Repairing all task order")
        
        // Get the context
        let context = PersistenceController.shared.container.viewContext
        
        // Ensure all items have displayOrder first
        ensureDisplayOrderExists()
        
        // Group tasks by project and assign display order
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            
            // Group by project
            let itemsByProject = Dictionary(grouping: items) { item in
                item.project?.objectID.uriRepresentation().absoluteString ?? "no-project"
            }
            
            print("📋 Repairing \(itemsByProject.count) groups of tasks")
            
            // Reindex each group
            for (projectKey, projectItems) in itemsByProject {
                // Sort by creation date as a fallback
                let sortedItems = projectItems.sorted { 
                    ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast)
                }
                
                print("  🔄 Repairing order for group: \(projectKey) (\(sortedItems.count) tasks)")
                
                // Assign display order with spacing
                for (index, item) in sortedItems.enumerated() {
                    let newOrder = Int32(index * 10)
                    item.setValue(newOrder, forKey: "displayOrder")
                }
            }
            
            // Save changes safely
            try? context.save()
            print("✅ All task ordering repaired")
            
            // Force a refresh notification
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
        } catch {
            print("❌ Error repairing task order: \(error)")
        }
    }
    
    /// Repair project ordering
    /// Sorts projects by name (or current order) and assigns new incremental display order values
    static func repairAllProjectOrder() {
        print("🔧 Repairing all project order")
        
        // Get the context
        let context = PersistenceController.shared.container.viewContext
        
        // Ensure all items have displayOrder first
        ensureDisplayOrderExists()
        
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(fetchRequest)
            
            // Sort by display order, fallback to alphabetical
            let sortedProjects = projects.sorted { 
                if $0.value(forKey: "displayOrder") as? Int32 != $1.value(forKey: "displayOrder") as? Int32 {
                    return ($0.value(forKey: "displayOrder") as? Int32 ?? 9999) < ($1.value(forKey: "displayOrder") as? Int32 ?? 9999)
                }
                return ($0.name ?? "") < ($1.name ?? "")
            }
            
            print("📋 Repairing \(sortedProjects.count) projects")
            
            // Assign display order with spacing
            for (index, project) in sortedProjects.enumerated() {
                let newOrder = Int32(index * 10)
                project.setValue(newOrder, forKey: "displayOrder")
                print("  🔄 Setting project '\(project.name ?? "Untitled")' display order: \(newOrder)")
            }
            
            // Save changes safely
            try? context.save()
            print("✅ All project ordering repaired")
            
            // Force a refresh notification
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: context
            )
        } catch {
            print("❌ Error repairing project order: \(error)")
        }
    }
}
