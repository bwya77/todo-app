//
//  ProjectTasksRequest.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData
import SwiftUI

struct ProjectTasksRequest {
    /// Creates a fetch request for active tasks in a project, ordered by display order
    static func activeTasksRequest(for project: Project) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@ AND (completed == NO OR (completed == YES AND logged == NO))", project)
        
        // Primary sort by display order, then fallback to due date
        request.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        return request
    }
    
    /// Creates a fetch request for logged tasks in a project
    static func loggedTasksRequest(for project: Project) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@ AND completed == YES AND logged == YES", project)
        
        // Sort by most recently completed first
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.completionDate, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        return request
    }
}
