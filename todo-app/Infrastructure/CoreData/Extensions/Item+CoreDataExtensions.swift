//
//  Item+CoreDataExtensions.swift
//  todo-app
//
//  Created on 3/12/25.
//  Updated for drag & drop on 3/15/25.
//

import Foundation
import CoreData

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
        
        // Set default values if necessary
        // Note: For Bool primitive types, we don't need to check for nil
        // But we set default values to ensure consistency
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
    /// - Returns: The newly created Item
    static func create(in context: NSManagedObjectContext, 
                      title: String, 
                      dueDate: Date? = nil, 
                      priority: Priority = .none,
                      isAllDay: Bool = false,
                      project: Project? = nil,
                      notes: String? = nil) -> Item {
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
        
        // Set initial display order for new items
        // Place it at the end of existing items in the same project
        if let project = project {
            let existingItems = fetchItemsForProject(project, in: context)
            if let maxOrder = existingItems.map({ $0.displayOrder }).max() {
                item.displayOrder = maxOrder + 1000 // Add spacing for future insertions
            } else {
                item.displayOrder = 0
            }
        } else {
            // For inbox items (no project)
            let inboxItems = fetchInboxItems(in: context)
            if let maxOrder = inboxItems.map({ $0.displayOrder }).max() {
                item.displayOrder = maxOrder + 1000
            } else {
                item.displayOrder = 0
            }
        }
        
        return item
    }
    
    /// Fetch items for a specific project
    /// - Parameters:
    ///   - project: The project to fetch items for
    ///   - context: The managed object context
    /// - Returns: Array of items in the project
    private static func fetchItemsForProject(_ project: Project, in context: NSManagedObjectContext) -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", project)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching items for project: \(error)")
            return []
        }
    }
    
    /// Fetch inbox items (items with no project)
    /// - Parameter context: The managed object context
    /// - Returns: Array of inbox items
    private static func fetchInboxItems(in context: NSManagedObjectContext) -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == nil")
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching inbox items: \(error)")
            return []
        }
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
    
    // MARK: - Display Order Operations
    
    /// Set the display order for this item
    /// - Parameters:
    ///   - order: The new display order value
    ///   - save: Whether to save the context
    func setDisplayOrder(_ order: Int32, save: Bool = true) {
        displayOrder = order
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving display order: \(error)")
            }
        }
    }
    
    /// Get all items with the same project as this item (siblings)
    /// - Returns: Array of items in the same project, sorted by display order
    func getSiblingsInProject() -> [Item] {
        guard let context = self.managedObjectContext else { return [] }
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        if let project = self.project {
            request.predicate = NSPredicate(format: "project == %@", project)
        } else {
            request.predicate = NSPredicate(format: "project == nil")
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching siblings: \(error)")
            return []
        }
    }
    
    /// Reorder this item to be before another item
    /// - Parameters:
    ///   - targetItem: The item that this item should appear before
    ///   - save: Whether to save the context after reordering
    func moveBeforeItem(_ targetItem: Item, save: Bool = true) {
        // Ensure items are in the same project
        guard self.project == targetItem.project else {
            print("Cannot reorder items in different projects")
            return
        }
        
        // Get all siblings sorted by display order
        var siblings = getSiblingsInProject()
        
        // Remove self from the array
        siblings.removeAll { $0 == self }
        
        // Find the index of the target item
        guard let targetIndex = siblings.firstIndex(of: targetItem) else {
            print("Target item not found in siblings")
            return
        }
        
        // Insert self at the target position
        siblings.insert(self, at: targetIndex)
        
        // Update display orders for all items
        Self.reorderItems(siblings, save: save)
    }
    
    /// Update display order for all items in a collection
    /// - Parameters:
    ///   - items: The items to reorder
    ///   - save: Whether to save the context
    static func reorderItems(_ items: [Item], save: Bool = true) {
        // Use a reasonable spacing between items to allow for later insertions
        // without having to reorder everything
        let orderSpacing: Int32 = 1000
        
        for (index, item) in items.enumerated() {
            item.displayOrder = Int32(index) * orderSpacing
        }
        
        if save, let context = items.first?.managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving after reordering: \(error)")
            }
        }
    }
}
