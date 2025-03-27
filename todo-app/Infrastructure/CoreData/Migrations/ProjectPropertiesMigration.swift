//
//  ProjectPropertiesMigration.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

/// Utility to initialize or update Project entity properties
struct ProjectPropertiesMigration {
    
    /// Initialize modifiedAt for all projects that don't have it
    /// - Parameter context: The managed object context
    static func initializeLastModifiedDate(in context: NSManagedObjectContext) {
        print("🔄 Initializing modifiedAt for all projects...")
        
        // Fetch all projects
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(fetchRequest)
            print("📉 Found \(projects.count) projects to update")
            
            // Update modifiedAt for each project
            for project in projects {
                // If we've added this property via a Category without doing a proper Core Data migration,
                // modifiedAt might be nil for existing records
                if project.modifiedAt == nil {
                    print("  → Setting modifiedAt for project '\(project.name ?? "Untitled")'")
                    project.modifiedAt = Date()
                }
            }
            
            // Save changes
            try context.save()
            print("✅ modifiedAt initialized for all projects")
            
        } catch {
            print("❌ Failed to initialize modifiedAt: \(error)")
        }
    }
    
    /// Update modifiedAt for a specific project
    /// - Parameters:
    ///   - project: The project to update
    ///   - context: The managed object context
    static func updateLastModifiedDate(for project: Project, in context: NSManagedObjectContext) {
        project.modifiedAt = Date()
        
        do {
            try context.save()
            print("✅ Updated modifiedAt for project: \(project.name ?? "Unknown")")
        } catch {
            print("❌ Failed to update modifiedAt: \(error)")
        }
    }
}
