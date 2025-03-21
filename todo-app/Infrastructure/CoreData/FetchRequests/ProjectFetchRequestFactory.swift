//
//  ProjectFetchRequestFactory.swift
//  todo-app
//
//  Created on 3/13/25.
//

import Foundation
import CoreData

/// A factory class for creating commonly used fetch requests for the Project entity
/// Centralizes fetch logic and improves reusability across the application
struct ProjectFetchRequestFactory {
    
    /// Creates a fetch request for all projects
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func allProjects(in context: NSManagedObjectContext) -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Check if displayOrder exists on the entity
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName["displayOrder"] != nil
        
        if hasDisplayOrder {
            // If displayOrder exists, sort by it
            request.sortDescriptors = [
                NSSortDescriptor(key: "displayOrder", ascending: true)
            ]
        } else {
            // Fallback to sorting by name
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Project.name, ascending: true)
            ]
        }
        
        return request
    }
    
    /// Creates a fetch request for a project by ID
    /// - Parameters:
    ///   - id: The UUID of the project to fetch
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func projectWithID(_ id: UUID, in context: NSManagedObjectContext) -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return request
    }
    
    /// Creates a fetch request for projects by name
    /// - Parameters:
    ///   - name: The name to search for (can be partial)
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func projectsWithName(_ name: String, in context: NSManagedObjectContext) -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Project.name, ascending: true)
        ]
        
        return request
    }
    
    /// Creates a fetch request for projects with tasks due on a specific date
    /// - Parameters:
    ///   - date: The date to check for tasks
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func projectsWithTasksDueOn(_ date: Date, in context: NSManagedObjectContext) -> NSFetchRequest<Project> {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "ANY items.dueDate >= %@ AND ANY items.dueDate < %@", 
                                        startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Project.name, ascending: true)
        ]
        
        return request
    }
    
    /// Configure batch fetching for projects
    /// - Parameters:
    ///   - request: The fetch request to configure
    ///   - batchSize: The batch size to use (default: 10)
    /// - Returns: The configured fetch request
    static func configureBatchFetching<T>(_ request: NSFetchRequest<T>, batchSize: Int = 10) -> NSFetchRequest<T> {
        request.fetchBatchSize = batchSize
        return request
    }
}

/// A factory class for creating commonly used fetch requests for the Tag entity
struct TagFetchRequestFactory {
    
    /// Creates a fetch request for all tags
    /// - Parameter context: The managed object context
    /// - Returns: A configured fetch request
    static func allTags(in context: NSManagedObjectContext) -> NSFetchRequest<Tag> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        
        return request
    }
    
    /// Creates a fetch request for a tag by ID
    /// - Parameters:
    ///   - id: The UUID of the tag to fetch
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tagWithID(_ id: UUID, in context: NSManagedObjectContext) -> NSFetchRequest<Tag> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return request
    }
    
    /// Creates a fetch request for tags by name
    /// - Parameters:
    ///   - name: The name to search for (can be partial)
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tagsWithName(_ name: String, in context: NSManagedObjectContext) -> NSFetchRequest<Tag> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        
        return request
    }
    
    /// Creates a fetch request for tags used in a project
    /// - Parameters:
    ///   - project: The project to fetch tags for
    ///   - context: The managed object context
    /// - Returns: A configured fetch request
    static func tagsForProject(_ project: Project, in context: NSManagedObjectContext) -> NSFetchRequest<Tag> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        
        request.predicate = NSPredicate(format: "ANY items.project == %@", project)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        
        return request
    }
}
