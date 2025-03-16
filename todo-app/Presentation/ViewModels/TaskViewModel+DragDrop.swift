//
//  TaskViewModel+DragDrop.swift
//  todo-app
//
//  Created on 3/15/25.
//

import Foundation
import CoreData

extension TaskViewModel {
    /// Handle reordering when a task is dragged and dropped onto another task
    /// - Parameters:
    ///   - sourceTask: The task being dragged
    ///   - targetTask: The task being dropped onto
    func reorderTask(_ sourceTask: Item, before targetTask: Item) {
        // Don't reorder if it's the same task
        guard sourceTask != targetTask else { return }
        
        // If source and target are in different projects, handle project change first
        if sourceTask.project != targetTask.project {
            sourceTask.project = targetTask.project
            try? viewContext.save()
        }
        
        // Use the Item extension's moveBeforeItem method
        sourceTask.moveBeforeItem(targetTask)
    }
    
    /// Find a task by its ID
    /// - Parameter id: The UUID to search for
    /// - Returns: The matching Item or nil if not found
    func findTask(with id: UUID) -> Item? {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error finding task with ID \(id): \(error)")
            return nil
        }
    }
}
