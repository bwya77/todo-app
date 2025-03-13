//
//  TodoAppMigrationPolicy.swift
//  todo-app
//
//  Created on 3/12/25.
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
}
