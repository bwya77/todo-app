//
//  TodoAppV2ToV3MigrationPolicy.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// Migration policy to handle adding displayOrder attribute to Item entity
final class TodoAppV2ToV3MigrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Call the super implementation first to create the destination entity
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Get the destination instance we just created
        guard let destInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            print("Warning: Failed to retrieve destination instance during migration")
            return
        }
        
        // Only process Item entities
        guard let itemClassName = destInstance.entity.managedObjectClassName, itemClassName.contains("Item") else {
            return
        }
        
        // Set initial displayOrder based on existing data
        
        // First try createdDate if available for chronological order
        if let createdDate = sInstance.value(forKey: "createdDate") as? Date {
            // Use timestamp to generate a reasonable order value
            let timestamp = Int32(createdDate.timeIntervalSinceReferenceDate)
            destInstance.setValue(timestamp, forKey: "displayOrder")
        } 
        // Fall back to using priority if available
        else if let priority = sInstance.value(forKey: "priority") as? Int16 {
            // Use priority as a starting point for ordering
            destInstance.setValue(Int32(priority), forKey: "displayOrder")
        }
        // Last resort - use a high default value
        else {
            destInstance.setValue(Int32.max - 1000, forKey: "displayOrder")
        }
    }
}
