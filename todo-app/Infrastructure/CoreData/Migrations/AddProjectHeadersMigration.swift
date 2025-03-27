//
//  AddProjectHeadersMigration.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

/// Migration policy for adding project headers
class AddProjectHeadersMigration: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Call the super implementation to create the destination instance
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Get the destination instance that was created
        guard let destinationItem = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            return
        }
        
        // If this is an Item entity, ensure the header relationship is nil
        if mapping.destinationEntityName == "Item" {
            destinationItem.setValue(nil, forKey: "header")
            destinationItem.setValue(nil, forKey: "headerId")
        }
        
        // If this is a Project entity, initialize empty headers relationship
        if mapping.destinationEntityName == "Project" {
            destinationItem.setValue(Set<NSManagedObject>(), forKey: "headers")
        }
    }
}
