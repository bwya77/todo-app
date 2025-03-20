//
//  AddDisplayOrderMigration.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// Migration policy to add displayOrder attribute to Item entity
class AddDisplayOrderMigrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Call the super implementation first
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Get the destination instance we just created
        guard let destInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            return
        }
        
        // Set a default displayOrder based on createdDate
        // This preserves relative ordering of existing tasks
        if let createdDate = sInstance.value(forKey: "createdDate") as? Date {
            // Convert date to a timestamp (seconds since reference date)
            let timestamp = createdDate.timeIntervalSinceReferenceDate
            
            // Use timestamp as initial ordering to preserve chronological order
            // We'll use a high enough number (10000) to leave room for manual reordering
            // Newer items should have higher timestamps and thus be at the bottom
            destInstance.setValue(Int32(timestamp), forKey: "displayOrder")
        } else {
            // If no created date, use a default high value
            destInstance.setValue(Int32.max - 1000, forKey: "displayOrder")
        }
    }
}
