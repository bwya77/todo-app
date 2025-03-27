//
//  ProjectHeadersMigrationPolicy.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

/// Migration policy for adding project headers and renaming lastModifiedDate to modifiedAt
class ProjectHeadersMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Call the super implementation to create the destination instance
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Get the destination instance that was created
        guard let destinationInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            return
        }
        
        // If this is a Project entity, handle the property rename
        if mapping.destinationEntityName == "Project" {
            // Handle lastModifiedDate to modifiedAt transition
            if let lastModifiedDate = sInstance.value(forKey: "lastModifiedDate") as? Date {
                destinationInstance.setValue(lastModifiedDate, forKey: "modifiedAt")
            } else {
                // If no lastModifiedDate exists, initialize modifiedAt
                destinationInstance.setValue(Date(), forKey: "modifiedAt")
            }
            
            // Initialize the headers relationship
            destinationInstance.setValue(Set<NSManagedObject>(), forKey: "headers")
        }
        
        // If this is an Item entity, ensure the header relationship is nil
        if mapping.destinationEntityName == "Item" {
            destinationInstance.setValue(nil, forKey: "header")
            destinationInstance.setValue(nil, forKey: "headerId")
        }
    }
}
