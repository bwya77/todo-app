//
//  InboxTasksRequest.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

struct InboxTasksRequest {
    /// Creates a fetch request for all tasks without a project (Inbox tasks)
    static func inboxTasksRequest() -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Specifically only get tasks that have no project (null/nil project) and are not completed
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "project == nil"),
            NSPredicate(format: "completed == NO")
        ])
        
        // Sort by display order first, then other attributes
        request.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        return request
    }
    
    /// Creates a fetch request for upcoming tasks
    static func upcomingTasksRequest() -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Get tasks due in the future
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "dueDate >= %@", startOfDay as NSDate)
        
        // Sort by due date, then display order
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(key: "displayOrder", ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    /// Creates a fetch request for completed tasks
    static func completedTasksRequest() -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Get completed tasks
        request.predicate = NSPredicate(format: "completed == YES")
        
        // Sort by completion date, most recent first
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.completionDate, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        return request
    }
}
