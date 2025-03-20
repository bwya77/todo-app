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
    /// Adds the displayOrder attribute to the Item entity if it doesn't exist
    func addDisplayOrderAttribute() {
        // Find the Item entity
        if let itemEntity = entitiesByName["Item"] {
            // Check if displayOrder property already exists
            if itemEntity.propertiesByName["displayOrder"] == nil {
                // Create the new attribute
                let displayOrderAttribute = NSAttributeDescription()
                displayOrderAttribute.name = "displayOrder"
                displayOrderAttribute.attributeType = .integer32AttributeType
                displayOrderAttribute.defaultValue = 0
                displayOrderAttribute.isOptional = false
                
                // Add it to the entity's properties
                var properties = itemEntity.properties
                properties.append(displayOrderAttribute)
                itemEntity.properties = properties
                
                print("✅ Added displayOrder attribute to Item entity")
            } else {
                print("ℹ️ displayOrder attribute already exists")
            }
        } else {
            print("❌ Could not find Item entity in model")
        }
    }
}

/// Critical utility for management of task display order
class DisplayOrderManager {
    /// Ensures all tasks have display order attribute by adding it to the model if needed,
    /// and checking existing items
    static func ensureDisplayOrderExists() {
        print("🔍 Ensuring displayOrder attribute exists for all tasks")
        
        do {
            // Get current model
            let container = PersistenceController.shared.container
            let model = container.managedObjectModel
            
            // Add the attribute to the model
            model.addDisplayOrderAttribute()
            
            // Get the context
            let context = container.viewContext
            
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
                try context.save()
                print("✅ Fixed displayOrder for \(fixedCount) tasks")
            } else {
                print("✓ All tasks have displayOrder attribute")
            }
            
            print("✅ Ensured displayOrder attribute exists")
        } catch {
            print("❌ Error ensuring displayOrder exists: \(error)")
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
            
            // Save the context
            try context.save()
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
}