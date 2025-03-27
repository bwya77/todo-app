//
//  ProjectHeadersRequest.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

/// Helper for creating optimized fetch requests for project headers
struct ProjectHeadersRequest {
    /// Create a fetch request for all headers in a project
    /// - Parameter project: The project to fetch headers for
    /// - Returns: A configured NSFetchRequest for ProjectHeader entities
    static func headersRequest(for project: Project) -> NSFetchRequest<ProjectHeader> {
        let request: NSFetchRequest<ProjectHeader> = ProjectHeader.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", project)
        request.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        return request
    }
    
    /// Create a fetch request for tasks in a specific header
    /// - Parameter header: The header to fetch tasks for
    /// - Returns: A configured NSFetchRequest for Item entities
    static func tasksForHeaderRequest(header: ProjectHeader) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "header == %@ AND (completed == NO OR (completed == YES AND logged == NO))", header)
        request.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        return request
    }
}
