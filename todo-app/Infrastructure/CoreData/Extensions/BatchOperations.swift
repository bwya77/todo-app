//
//  BatchOperations.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    /// Complete all tasks in a project
    /// - Parameters:
    ///   - project: The project containing tasks to complete
    ///   - includeLogged: Whether to include already logged tasks
    /// - Returns: Number of tasks that were updated
    @discardableResult
    func completeAllTasksInProject(_ project: Project, includeLogged: Bool = false) -> Int {
        guard let projectID = project.id else { return 0 }
        
        // First count the items that will be affected
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Create a predicate for non-logged tasks if needed
        var predicates = [
            NSPredicate(format: "project.id == %@", projectID as CVarArg),
            NSPredicate(format: "completed == NO")
        ]
        
        if !includeLogged {
            predicates.append(NSPredicate(format: "logged == NO"))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Count the affected items first
        let affectedCount: Int
        do {
            affectedCount = try count(for: fetchRequest)
        } catch {
            print("Error counting tasks to complete: \(error)")
            return 0
        }
        
        // If no items to affect, return early
        if affectedCount == 0 {
            return 0
        }
        
        // Now perform the batch update using direct SQL update for efficiency
        let batchRequest = NSBatchUpdateRequest(entityName: "Item")
        batchRequest.predicate = fetchRequest.predicate
        batchRequest.propertiesToUpdate = [
            "completed": true,
            "completionDate": Date()
        ]
        
        do {
            try execute(batchRequest)
            return affectedCount
        } catch {
            print("Error completing all tasks in project: \(error)")
            return 0
        }
    }
    
    /// Mark all completed tasks in a project as logged
    /// - Parameter project: The project containing tasks to log
    /// - Returns: Number of tasks that were updated
    @discardableResult
    func logAllCompletedTasksInProject(_ project: Project) -> Int {
        guard let projectID = project.id else { return 0 }
        
        // Create the predicate to find completed but not logged tasks
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "project.id == %@", projectID as CVarArg),
            NSPredicate(format: "completed == YES"),
            NSPredicate(format: "logged == NO")
        ])
        
        // Count the affected items first
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = predicate
        
        let affectedCount: Int
        do {
            affectedCount = try count(for: fetchRequest)
        } catch {
            print("Error counting tasks to log: \(error)")
            return 0
        }
        
        // If no items to affect, return early
        if affectedCount == 0 {
            return 0
        }
        
        // Now perform the batch update
        let batchRequest = NSBatchUpdateRequest(entityName: "Item")
        batchRequest.predicate = predicate
        batchRequest.propertiesToUpdate = ["logged": true]
        
        do {
            try execute(batchRequest)
            return affectedCount
        } catch {
            print("Error logging all completed tasks in project: \(error)")
            return 0
        }
    }
    
    /// Delete all completed and logged tasks in a project
    /// - Parameter project: The project containing tasks to delete
    /// - Returns: Number of tasks that were deleted
    @discardableResult
    func deleteCompletedAndLoggedTasksInProject(_ project: Project) -> Int {
        guard let projectID = project.id else { return 0 }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Item")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "project.id == %@", projectID as CVarArg),
            NSPredicate(format: "completed == YES"),
            NSPredicate(format: "logged == YES")
        ])
        
        // First count how many items will be deleted
        let count: Int
        do {
            count = try self.count(for: fetchRequest)
        } catch {
            print("Error counting items to delete: \(error)")
            return 0
        }
        
        // If no items to delete, return early
        if count == 0 {
            return 0
        }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try execute(deleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
                return count // Return the count we got before deletion
            }
            return 0
        } catch {
            print("Error deleting completed and logged tasks: \(error)")
            return 0
        }
    }
    
    /// Clean up orphaned items (no project and completed)
    /// - Returns: Number of orphaned items deleted
    @discardableResult
    func cleanupOrphanedItems() -> Int {
        // Find items that are completed, logged, and have no project
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Item")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "project == nil"),
            NSPredicate(format: "completed == YES"),
            NSPredicate(format: "logged == YES")
        ])
        
        // First count how many items will be deleted
        let count: Int
        do {
            count = try self.count(for: fetchRequest)
        } catch {
            print("Error counting orphaned items: \(error)")
            return 0
        }
        
        // If no items to delete, return early
        if count == 0 {
            return 0
        }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try execute(deleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
                return count // Return the count we got before deletion
            }
            return 0
        } catch {
            print("Error cleaning up orphaned items: \(error)")
            return 0
        }
    }
}
