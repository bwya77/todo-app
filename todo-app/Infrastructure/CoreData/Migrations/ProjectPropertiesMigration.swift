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
    
    /// Initialize lastModifiedDate for all projects that don't have it
    /// - Parameter context: The managed object context
    static func initializeLastModifiedDate(in context: NSManagedObjectContext) {
        print("🔄 Initializing lastModifiedDate for all projects...")
        
        // Fetch all projects
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        do {
            let projects = try context.fetch(fetchRequest)
            print("📉 Found \(projects.count) projects to update")
            
            // Update lastModifiedDate for each project
            for project in projects {
                // If we've added this property via a Category without doing a proper Core Data migration,
                // lastModifiedDate might be nil for existing records
                if project.lastModifiedDate == nil {
                    print("  → Setting lastModifiedDate for project '\(project.name ?? "Untitled")'")
                    project.lastModifiedDate = Date()
                }
            }
            
            // Save changes
            try context.save()
            print("✅ lastModifiedDate initialized for all projects")
            
        } catch {
            print("❌ Failed to initialize lastModifiedDate: \(error)")
        }
    }
    
    /// Update lastModifiedDate for a specific project
    /// - Parameters:
    ///   - project: The project to update
    ///   - context: The managed object context
    static func updateLastModifiedDate(for project: Project, in context: NSManagedObjectContext) {
        project.lastModifiedDate = Date()
        
        do {
            try context.save()
            print("✅ Updated lastModifiedDate for project: \(project.name ?? "Unknown")")
        } catch {
            print("❌ Failed to update lastModifiedDate: \(error)")
        }
    }
}
