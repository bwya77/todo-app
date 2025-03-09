//
//  DefaultDataProvider.swift
//  todo-app
//
//  Created on 3/9/25.
//

import CoreData
import Foundation

/// Provides default data for the application if none exists
class DefaultDataProvider {
    
    /// The shared instance of the provider
    static let shared = DefaultDataProvider()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Call this method to ensure default data exists on app launch
    func ensureDefaultData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Check if we have any projects
        let projectRequest: NSFetchRequest<Project> = Project.fetchRequest()
        projectRequest.fetchLimit = 1
        
        do {
            let projectCount = try context.count(for: projectRequest)
            
            if projectCount == 0 {
                // Create default projects
                createDefaultProjects(in: context)
            }
        } catch {
            print("Error checking for projects: \(error)")
        }
        
        // Check if we have any tags
        let tagRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        tagRequest.fetchLimit = 1
        
        do {
            let tagCount = try context.count(for: tagRequest)
            
            if tagCount == 0 {
                // Create default tags
                createDefaultTags(in: context)
            }
        } catch {
            print("Error checking for tags: \(error)")
        }
    }
    
    /// Creates default projects if none exist
    private func createDefaultProjects(in context: NSManagedObjectContext) {
        let projectData = [
            ("Work", "blue"),
            ("Personal", "green"),
            ("Health", "red"),
            ("Finance", "orange")
        ]
        
        for (name, color) in projectData {
            let project = Project(context: context)
            project.id = UUID()
            project.name = name
            project.color = color
        }
        
        // Save the context
        do {
            try context.save()
            print("Created default projects")
        } catch {
            print("Error saving default projects: \(error)")
        }
    }
    
    /// Creates default tags if none exist
    private func createDefaultTags(in context: NSManagedObjectContext) {
        let tagData = [
            ("Important", "red"),
            ("Later", "orange"),
            ("Quick", "green"),
            ("Home", "blue"),
            ("Research", "purple")
        ]
        
        for (name, color) in tagData {
            let tag = Tag(context: context)
            tag.id = UUID()
            tag.name = name
            tag.color = color
        }
        
        // Save the context
        do {
            try context.save()
            print("Created default tags")
        } catch {
            print("Error saving default tags: \(error)")
        }
    }
}
