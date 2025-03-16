//
//  TodoAppMigrationPolicy.swift
//  todo-app
//
//  Created on 3/12/25.
//  Updated for v3 migration on 3/15/25.
//

import Foundation
import CoreData

class TodoAppMigrationPolicy: NSEntityMigrationPolicy {
    
    // This method will handle custom attribute mapping during migration
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Get the destination instance that was created
        guard let destInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            return
        }
        
        // Handle migration for Item entity
        if destInstance.entity.name == "Item" {
            // Validate that all required attributes have appropriate values
            if destInstance.value(forKey: "id") == nil {
                destInstance.setValue(UUID(), forKey: "id")
            }
            
            if destInstance.value(forKey: "createdDate") == nil {
                destInstance.setValue(Date(), forKey: "createdDate")
            }
            
            if destInstance.value(forKey: "title") == nil {
                destInstance.setValue("", forKey: "title")
            }
            
            // Handle v2 to v3 migration - set initial displayOrder
            // We're checking if the model has the displayOrder attribute but the source doesn't
            if destInstance.entity.attributesByName["displayOrder"] != nil &&
               sInstance.entity.attributesByName["displayOrder"] == nil {
                // Set initial display order based on creation date as a reasonable default
                if let createdDate = sInstance.value(forKey: "createdDate") as? Date {
                    let timeInterval = createdDate.timeIntervalSince1970
                    // Limit to reasonable Int32 range
                    let displayOrder = Int32(min(Double(Int32.max), timeInterval))
                    destInstance.setValue(displayOrder, forKey: "displayOrder")
                } else {
                    // Fallback to a random value if no created date
                    destInstance.setValue(Int32.random(in: 0..<10000), forKey: "displayOrder")
                }
            }
        }
        
        // Handle migration for Project entity
        else if destInstance.entity.name == "Project" {
            if destInstance.value(forKey: "id") == nil {
                destInstance.setValue(UUID(), forKey: "id")
            }
            
            if destInstance.value(forKey: "name") == nil {
                destInstance.setValue("Untitled Project", forKey: "name")
            }
            
            if destInstance.value(forKey: "color") == nil {
                destInstance.setValue("gray", forKey: "color")
            }
        }
        
        // Handle migration for Tag entity
        else if destInstance.entity.name == "Tag" {
            if destInstance.value(forKey: "id") == nil {
                destInstance.setValue(UUID(), forKey: "id")
            }
            
            if destInstance.value(forKey: "name") == nil {
                destInstance.setValue("Untitled Tag", forKey: "name")
            }
            
            if destInstance.value(forKey: "color") == nil {
                destInstance.setValue("gray", forKey: "color")
            }
        }
    }
    
    // After migration is complete, organize items by project and adjust their display orders
    override func endInstanceCreation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.endInstanceCreation(forMapping: mapping, manager: manager)
        
        // Only proceed if this is the migration for the Item entity
        guard mapping.destinationEntityName == "Item",
              mapping.sourceEntityName == "Item" else {
            return
        }
        
        // Get all destination instances
        let request = NSFetchRequest<NSManagedObject>(entityName: "Item")
        let context = manager.destinationContext
        
        do {
            let allItems = try context.fetch(request)
            
            // Group items by project
            let itemsByProject = Dictionary(grouping: allItems) { item -> String in
                if let project = item.value(forKeyPath: "project.id") as? UUID {
                    return project.uuidString
                }
                return "no-project"
            }
            
            // For each project group, set display orders with appropriate spacing
            for (_, items) in itemsByProject {
                // Sort by created date to preserve existing implied ordering
                let sortedItems = items.sorted { 
                    guard let date1 = $0.value(forKey: "createdDate") as? Date,
                          let date2 = $1.value(forKey: "createdDate") as? Date else {
                        return false
                    }
                    return date1 < date2
                }
                
                // Set display order with spacing of 1000 between items
                for (index, item) in sortedItems.enumerated() {
                    let orderSpacing: Int32 = 1000
                    item.setValue(Int32(index) * orderSpacing, forKey: "displayOrder")
                }
            }
            
            // Save the context to persist these changes
            try context.save()
            
        } catch {
            print("Error during migration finalization: \(error)")
        }
    }
}
