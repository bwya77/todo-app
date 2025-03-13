//
//  Tag+CoreDataExtensions.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

extension Tag {
    /// Validates and ensures all required properties are set correctly
    func validateAndSetDefaults() {
        // Ensure ID is set
        if id == nil {
            id = UUID()
        }
        
        // Ensure name is never nil
        if name == nil {
            name = "Untitled Tag"
        }
        
        // Ensure color is set with a default
        if color == nil {
            color = "gray"
        }
    }
    
    /// Creates a new Tag with required properties
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the tag in
    ///   - name: The name of the tag
    ///   - color: The color of the tag (defaults to gray)
    /// - Returns: The newly created Tag
    static func create(in context: NSManagedObjectContext, name: String, color: String = "gray") -> Tag {
        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = name
        tag.color = color
        return tag
    }
    
    /// Get all tasks with this tag (excluding completed and logged tasks)
    /// - Returns: Array of active tasks
    func activeTasks() -> [Item] {
        guard let items = items as? Set<Item> else { return [] }
        return items.filter { !$0.completed && !$0.logged }.sorted {
            // Sort by due date (nil dates at the end), then by priority
            if let date1 = $0.dueDate, let date2 = $1.dueDate {
                return date1 < date2
            } else if $0.dueDate != nil {
                return true
            } else if $1.dueDate != nil {
                return false
            } else {
                return $0.priority > $1.priority
            }
        }
    }
    
    /// Get all completed tasks with this tag
    /// - Returns: Array of completed tasks
    func completedTasks() -> [Item] {
        guard let items = items as? Set<Item> else { return [] }
        return items.filter { $0.completed }.sorted {
            // Sort by completion date (newer first)
            if let date1 = $0.completionDate, let date2 = $1.completionDate {
                return date1 > date2
            } else if $0.completionDate != nil {
                return true
            } else if $1.completionDate != nil {
                return false
            } else {
                return $0.createdDate ?? Date() > $1.createdDate ?? Date()
            }
        }
    }
    
    /// Get the count of active (incomplete) tasks with this tag
    var activeTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.filter { !$0.completed && !$0.logged }.count
    }
    
    /// Get the count of completed tasks with this tag
    var completedTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.filter { $0.completed }.count
    }
    
    /// Get the count of all tasks with this tag
    var totalTaskCount: Int {
        guard let items = items as? Set<Item> else { return 0 }
        return items.count
    }
    
    /// Add this tag to a task
    /// - Parameters:
    ///   - task: The task to add this tag to
    ///   - save: Whether to save the context after adding
    func addToTask(_ task: Item, save: Bool = true) {
        task.addTag(self, save: save)
    }
    
    /// Remove this tag from a task
    /// - Parameters:
    ///   - task: The task to remove this tag from
    ///   - save: Whether to save the context after removing
    func removeFromTask(_ task: Item, save: Bool = true) {
        task.removeTag(self, save: save)
    }
}
