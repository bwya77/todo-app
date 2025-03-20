//
//  Item+CoreDataExtensions.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData
import SwiftUI

extension Item {
    /// Validates and ensures all required properties are set correctly
    func validateAndSetDefaults() {
        // Ensure ID is set
        if id == nil {
            id = UUID()
        }
        
        // Ensure created date is set
        if createdDate == nil {
            createdDate = Date()
        }
        
        // Ensure title is never nil (empty string is acceptable for draft tasks)
        if title == nil {
            title = ""
        }
        
        // CRITICAL: Make sure displayOrder is set
        if value(forKey: "displayOrder") == nil {
            // Default to a high number so it appears at the end
            setValue(9999, forKey: "displayOrder")
        }
    }
    
    /// Creates a new Item with required properties
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the item in
    ///   - title: The title of the task
    ///   - dueDate: Optional due date
    ///   - priority: Task priority (defaults to .none)
    ///   - isAllDay: Whether this is an all-day task
    ///   - project: The project this task belongs to (optional)
    ///   - notes: Optional notes for the task
    ///   - displayOrder: Optional custom display order (if nil, will be set automatically)
    /// - Returns: The newly created Item
    static func create(in context: NSManagedObjectContext, 
                      title: String, 
                      dueDate: Date? = nil, 
                      priority: Priority = .none,
                      isAllDay: Bool = false,
                      project: Project? = nil,
                      notes: String? = nil,
                      displayOrder: Int32? = nil) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.title = title
        item.createdDate = Date()
        item.dueDate = dueDate
        item.priority = priority.rawValue
        item.completed = false
        item.logged = false
        item.isAllDay = isAllDay
        item.project = project
        item.notes = notes
        
        // CRITICAL: Always set display order - use direct setValue to bypass access control
        if let displayOrder = displayOrder {
            item.setValue(displayOrder, forKey: "displayOrder")
        } else {
            // For new items, determine displayOrder by fetching the current max order value
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = project != nil ? NSPredicate(format: "project == %@", project!) : NSPredicate(format: "project == nil")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try context.fetch(fetchRequest)
                let maxOrder = results.first?.value(forKey: "displayOrder") as? Int32 ?? 0
                item.setValue(maxOrder + 10, forKey: "displayOrder") // Add 10 for spacing
            } catch {
                // If fetch fails, use current timestamp as a fallback
                let timestamp = Int32(Date().timeIntervalSinceReferenceDate)
                item.setValue(timestamp, forKey: "displayOrder")
            }
        }
        return item
    }
    
    /// Mark a task as completed
    /// - Parameter save: Whether to save the context after making changes
    /// - Returns: True if task was newly completed, false if it was already completed
    @discardableResult
    func markAsCompleted(save: Bool = true) -> Bool {
        if completed {
            return false
        }
        
        completed = true
        completionDate = Date()
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving completion state: \(error)")
            }
        }
        
        return true
    }
    
    /// Mark a task as incomplete
    /// - Parameter save: Whether to save the context after making changes
    /// - Returns: True if task was newly marked incomplete, false if it was already incomplete
    @discardableResult
    func markAsIncomplete(save: Bool = true) -> Bool {
        if !completed {
            return false
        }
        
        completed = false
        completionDate = nil
        logged = false
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving completion state: \(error)")
            }
        }
        
        return true
    }
    
    /// Toggle a task's completion state
    /// - Parameter save: Whether to save the context after toggling
    func toggleCompletion(save: Bool = true) {
        if completed {
            markAsIncomplete(save: save)
        } else {
            markAsCompleted(save: save)
        }
    }
    
    /// Mark a task as logged
    /// - Parameter save: Whether to save the context after making changes
    func markAsLogged(save: Bool = true) {
        logged = true
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving logged state: \(error)")
            }
        }
    }
    
    /// Add a tag to this task
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - save: Whether to save the context after adding
    func addTag(_ tag: Tag, save: Bool = true) {
        let tagSet = tags?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        tagSet.add(tag)
        tags = tagSet
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving after adding tag: \(error)")
            }
        }
    }
    
    /// Remove a tag from this task
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - save: Whether to save the context after removing
    func removeTag(_ tag: Tag, save: Bool = true) {
        guard let tagSet = tags?.mutableCopy() as? NSMutableSet else { return }
        
        tagSet.remove(tag)
        tags = tagSet
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving after removing tag: \(error)")
            }
        }
    }
    
    /// Get the priority as a Priority enum
    var priorityEnum: Priority {
        return Priority.from(priority)
    }
    
    /// Set the priority using a Priority enum
    func setPriority(_ newPriority: Priority, save: Bool = true) {
        priority = newPriority.rawValue
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving priority: \(error)")
            }
        }
    }
    
    // MARK: - Display Order Access
    
    /// Direct access method for display order (adding to avoid conflict with generated property)
    func getDisplayOrder() -> Int32 {
        // Use direct access to the property
        return self.value(forKey: "displayOrder") as? Int32 ?? 9999
    }
    
    /// Direct setting method for display order
    func setDisplayOrder(_ newValue: Int32) {
        // Use direct access to set the property
        self.setValue(newValue, forKey: "displayOrder")
    }
    
    /// Updates display order and persists changes
    func updateDisplayOrder(_ newOrder: Int32, save: Bool = true) {
        // Set the display order directly
        self.setDisplayOrder(newOrder)
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
                print("Saved display order \(newOrder) for task \(title ?? "unknown")")
            } catch {
                print("Error saving display order: \(error)")
            }
        }
    }
}
