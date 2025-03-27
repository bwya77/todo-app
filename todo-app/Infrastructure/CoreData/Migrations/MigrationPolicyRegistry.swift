//
//  MigrationPolicyRegistry.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

/// Registry to map migration policies to model version transitions
struct MigrationPolicyRegistry {
    
    /// Register custom migration policies for Core Data migrations
    static func registerMigrationPolicies() {
        NSEntityMigrationPolicy.registerMigrationPolicies([
            "TodoAppV2ToV3MigrationPolicy": TodoAppV2ToV3MigrationPolicy.self,
            "AddProjectHeadersMigration": AddProjectHeadersMigration.self,
            "ProjectHeadersMigrationPolicy": ProjectHeadersMigrationPolicy.self
        ])
    }
    
    /// Add this method to the migration mapping model
    static func mappingModelForSourceModel(_ sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        // Try custom mapping model first
        do {
            if let customMapping = try NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destinationModel) {
                return customMapping
            }
            
            // Try inferred mapping model
            return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        } catch {
            print("Failed to create mapping model: \(error)")
            return nil
        }
    }
}

extension NSEntityMigrationPolicy {
    /// Register custom migration policies
    static func registerMigrationPolicies(_ policies: [String: AnyClass]) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let selector = NSSelectorFromString("setEntityMigrationPolicyClassNameMapping:")
        guard responds(to: selector) else { return }
        
        // Create a mutable copy of existing policies
        var mutablePolicies: [String: AnyClass] = [:]
        
        // Get existing policies if any
        if let existingMapping = self.perform(NSSelectorFromString("entityMigrationPolicyClassNameMapping"))?.takeUnretainedValue() as? [String: AnyClass] {
            for (key, existingPolicyClass) in existingMapping {
                mutablePolicies[key] = existingPolicyClass
            }
        }
        
        // Add new policies
        for (key, newPolicyClass) in policies {
            mutablePolicies[key] = newPolicyClass
        }
        
        // Set the updated mapping
        _ = self.perform(selector, with: mutablePolicies)
    }
}
